import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import {
  PaginationDto,
  paginate,
  paginationSkip,
} from '../common/dto/pagination.dto';
import { moneyToNumber } from '../common/utils/decimal.util';
import { PrismaService } from '../prisma/prisma.service';
import { STORAGE_SERVICE } from '../storage/storage.interface';
import type { StorageService } from '../storage/storage.interface';
import {
  CreateCategoryDto,
  CreateProductDto,
  CreatePromotionDto,
  UpdateCategoryDto,
  UpdateProductDto,
  UpdatePromotionDto,
} from './dto/catalog.dto';

@Injectable()
export class CatalogService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(STORAGE_SERVICE) private readonly storage: StorageService,
  ) {}

  private withImageUrl<T extends { imageKey?: string | null }>(row: T) {
    return {
      ...row,
      imageUrl: row.imageKey ? this.storage.getPublicUrl(row.imageKey) : null,
    };
  }

  // --- Public ---

  listCategories() {
    return this.prisma.category
      .findMany({
        where: { isActive: true },
        orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
      })
      .then((rows) => rows.map((r) => this.withImageUrl(r)));
  }

  async getCategory(idOrSlug: string) {
    const category = await this.prisma.category.findFirst({
      where: {
        OR: [{ id: idOrSlug }, { slug: idOrSlug }],
        isActive: true,
      },
    });
    if (!category) {
      throw new NotFoundException('Category not found');
    }
    return this.withImageUrl(category);
  }

  async listProducts(
    query: PaginationDto & { categoryId?: string; q?: string },
  ) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const where = {
      isAvailable: true,
      ...(query.categoryId ? { categoryId: query.categoryId } : {}),
      ...(query.q
        ? { name: { contains: query.q, mode: 'insensitive' as const } }
        : {}),
      category: { isActive: true },
    };

    const [total, rows] = await this.prisma.$transaction([
      this.prisma.product.count({ where }),
      this.prisma.product.findMany({
        where,
        skip: paginationSkip(page, limit),
        take: limit,
        orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
        include: { category: { select: { id: true, name: true, slug: true } } },
      }),
    ]);

    return paginate(
      rows.map((p) => ({
        ...this.withImageUrl(p),
        price: moneyToNumber(p.price),
        oldPrice: p.oldPrice != null ? moneyToNumber(p.oldPrice) : null,
      })),
      total,
      page,
      limit,
    );
  }

  async getProduct(id: string) {
    const product = await this.prisma.product.findFirst({
      where: { id, isAvailable: true, category: { isActive: true } },
      include: { category: { select: { id: true, name: true, slug: true } } },
    });
    if (!product) {
      throw new NotFoundException('Product not found');
    }
    return {
      ...this.withImageUrl(product),
      price: moneyToNumber(product.price),
      oldPrice:
        product.oldPrice != null ? moneyToNumber(product.oldPrice) : null,
    };
  }

  async listPromotions() {
    const now = new Date();
    const rows = await this.prisma.promotion.findMany({
      where: {
        isActive: true,
        AND: [
          { OR: [{ startsAt: null }, { startsAt: { lte: now } }] },
          { OR: [{ endsAt: null }, { endsAt: { gte: now } }] },
        ],
      },
      orderBy: [{ sortOrder: 'asc' }, { createdAt: 'desc' }],
    });
    return rows.map((r) => this.withImageUrl(r));
  }

  // --- Admin categories ---

  adminListCategories(query: PaginationDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    return this.prisma
      .$transaction([
        this.prisma.category.count(),
        this.prisma.category.findMany({
          skip: paginationSkip(page, limit),
          take: limit,
          orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
        }),
      ])
      .then(([total, rows]) =>
        paginate(
          rows.map((r) => this.withImageUrl(r)),
          total,
          page,
          limit,
        ),
      );
  }

  createCategory(dto: CreateCategoryDto) {
    return this.prisma.category
      .create({ data: dto })
      .then((r) => this.withImageUrl(r));
  }

  async updateCategory(id: string, dto: UpdateCategoryDto) {
    await this.ensureCategory(id);
    return this.prisma.category
      .update({ where: { id }, data: dto })
      .then((r) => this.withImageUrl(r));
  }

  async deleteCategory(id: string) {
    await this.ensureCategory(id);
    await this.prisma.category.delete({ where: { id } });
    return { success: true };
  }

  // --- Admin products ---

  adminListProducts(query: PaginationDto & { categoryId?: string }) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const where = query.categoryId ? { categoryId: query.categoryId } : {};
    return this.prisma
      .$transaction([
        this.prisma.product.count({ where }),
        this.prisma.product.findMany({
          where,
          skip: paginationSkip(page, limit),
          take: limit,
          orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
        }),
      ])
      .then(([total, rows]) =>
        paginate(
          rows.map((p) => ({
            ...this.withImageUrl(p),
            price: moneyToNumber(p.price),
            oldPrice: p.oldPrice != null ? moneyToNumber(p.oldPrice) : null,
          })),
          total,
          page,
          limit,
        ),
      );
  }

  createProduct(dto: CreateProductDto) {
    return this.prisma.product
      .create({
        data: {
          ...dto,
          description: dto.description ?? '',
        },
      })
      .then((p) => ({
        ...this.withImageUrl(p),
        price: moneyToNumber(p.price),
        oldPrice: p.oldPrice != null ? moneyToNumber(p.oldPrice) : null,
      }));
  }

  async updateProduct(id: string, dto: UpdateProductDto) {
    await this.ensureProduct(id);
    return this.prisma.product
      .update({ where: { id }, data: dto })
      .then((p) => ({
        ...this.withImageUrl(p),
        price: moneyToNumber(p.price),
        oldPrice: p.oldPrice != null ? moneyToNumber(p.oldPrice) : null,
      }));
  }

  async deleteProduct(id: string) {
    await this.ensureProduct(id);
    await this.prisma.product.delete({ where: { id } });
    return { success: true };
  }

  // --- Admin promotions ---

  adminListPromotions(query: PaginationDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    return this.prisma
      .$transaction([
        this.prisma.promotion.count(),
        this.prisma.promotion.findMany({
          skip: paginationSkip(page, limit),
          take: limit,
          orderBy: [{ sortOrder: 'asc' }, { createdAt: 'desc' }],
        }),
      ])
      .then(([total, rows]) =>
        paginate(
          rows.map((r) => this.withImageUrl(r)),
          total,
          page,
          limit,
        ),
      );
  }

  createPromotion(dto: CreatePromotionDto) {
    return this.prisma.promotion
      .create({
        data: {
          ...dto,
          startsAt: dto.startsAt ? new Date(dto.startsAt) : undefined,
          endsAt: dto.endsAt ? new Date(dto.endsAt) : undefined,
        },
      })
      .then((r) => this.withImageUrl(r));
  }

  async updatePromotion(id: string, dto: UpdatePromotionDto) {
    await this.ensurePromotion(id);
    return this.prisma.promotion
      .update({
        where: { id },
        data: {
          ...dto,
          startsAt:
            dto.startsAt === undefined
              ? undefined
              : dto.startsAt
                ? new Date(dto.startsAt)
                : null,
          endsAt:
            dto.endsAt === undefined
              ? undefined
              : dto.endsAt
                ? new Date(dto.endsAt)
                : null,
        },
      })
      .then((r) => this.withImageUrl(r));
  }

  async deletePromotion(id: string) {
    await this.ensurePromotion(id);
    await this.prisma.promotion.delete({ where: { id } });
    return { success: true };
  }

  private async ensureCategory(id: string) {
    const row = await this.prisma.category.findUnique({ where: { id } });
    if (!row) throw new NotFoundException('Category not found');
  }

  private async ensureProduct(id: string) {
    const row = await this.prisma.product.findUnique({ where: { id } });
    if (!row) throw new NotFoundException('Product not found');
  }

  private async ensurePromotion(id: string) {
    const row = await this.prisma.promotion.findUnique({ where: { id } });
    if (!row) throw new NotFoundException('Promotion not found');
  }
}
