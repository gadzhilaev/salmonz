import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '../../generated/prisma/client';
import { OrderStatus } from '../../generated/prisma/enums';
import {
  PaginationDto,
  paginate,
  paginationSkip,
} from '../common/dto/pagination.dto';
import { moneyToNumber } from '../common/utils/decimal.util';
import { calcOrderMoney } from '../common/utils/money.util';
import { canTransitionOrderStatus } from '../common/utils/order-status.util';
import { PrismaService } from '../prisma/prisma.service';
import { CreateOrderDto } from './dto/order.dto';

@Injectable()
export class OrdersService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, dto: CreateOrderDto) {
    const existing = await this.prisma.order.findUnique({
      where: {
        userId_idempotencyKey: {
          userId,
          idempotencyKey: dto.idempotencyKey,
        },
      },
      include: { items: true },
    });
    if (existing) {
      return this.serializeOrder(existing);
    }

    const address = await this.prisma.address.findUnique({
      where: { id: dto.addressId },
    });
    if (!address || address.userId !== userId) {
      throw new BadRequestException('Invalid address');
    }

    const productIds = [...new Set(dto.items.map((i) => i.productId))];
    const products = await this.prisma.product.findMany({
      where: { id: { in: productIds } },
    });
    if (products.length !== productIds.length) {
      throw new BadRequestException('One or more products not found');
    }

    const unavailable = products.filter((p) => !p.isAvailable);
    if (unavailable.length) {
      throw new BadRequestException(
        `Unavailable products: ${unavailable.map((p) => p.name).join(', ')}`,
      );
    }

    const productMap = new Map(products.map((p) => [p.id, p]));
    const lineInputs = dto.items.map((item) => {
      const product = productMap.get(item.productId)!;
      return {
        productId: product.id,
        productNameSnapshot: product.name,
        unitPrice: moneyToNumber(product.price),
        quantity: item.quantity,
      };
    });

    const money = calcOrderMoney(lineInputs);
    const publicNumber = await this.nextPublicNumber();

    const addressSnapshot = {
      title: address.title,
      city: address.city,
      street: address.street,
      house: address.house,
      apartment: address.apartment,
      entrance: address.entrance,
      floor: address.floor,
      comment: address.comment,
    };

    try {
      const order = await this.prisma.order.create({
        data: {
          publicNumber,
          userId,
          addressSnapshot,
          phone: dto.phone,
          comment: dto.comment,
          status: OrderStatus.NEW,
          subtotal: money.subtotal,
          deliveryFee: money.deliveryFee,
          total: money.total,
          idempotencyKey: dto.idempotencyKey,
          items: {
            create: lineInputs.map((line, idx) => ({
              productId: line.productId,
              productNameSnapshot: line.productNameSnapshot,
              unitPrice: money.lines[idx].unitPrice,
              quantity: money.lines[idx].quantity,
              lineTotal: money.lines[idx].lineTotal,
            })),
          },
        },
        include: { items: true },
      });
      return this.serializeOrder(order);
    } catch (e) {
      if (
        e instanceof Prisma.PrismaClientKnownRequestError &&
        e.code === 'P2002'
      ) {
        const again = await this.prisma.order.findUnique({
          where: {
            userId_idempotencyKey: {
              userId,
              idempotencyKey: dto.idempotencyKey,
            },
          },
          include: { items: true },
        });
        if (again) return this.serializeOrder(again);
      }
      throw e;
    }
  }

  async listMine(userId: string, query: PaginationDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const where = { userId };
    const [total, rows] = await this.prisma.$transaction([
      this.prisma.order.count({ where }),
      this.prisma.order.findMany({
        where,
        skip: paginationSkip(page, limit),
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: { items: true },
      }),
    ]);
    return paginate(
      rows.map((o) => this.serializeOrder(o)),
      total,
      page,
      limit,
    );
  }

  async getMine(userId: string, id: string) {
    const order = await this.prisma.order.findUnique({
      where: { id },
      include: { items: true },
    });
    if (!order) throw new NotFoundException('Order not found');
    if (order.userId !== userId) throw new ForbiddenException();
    return this.serializeOrder(order);
  }

  async adminList(query: PaginationDto & { status?: OrderStatus }) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const where = query.status ? { status: query.status } : {};
    const [total, rows] = await this.prisma.$transaction([
      this.prisma.order.count({ where }),
      this.prisma.order.findMany({
        where,
        skip: paginationSkip(page, limit),
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          items: true,
          user: { select: { id: true, email: true, name: true, phone: true } },
        },
      }),
    ]);
    return paginate(
      rows.map((o) => this.serializeOrder(o)),
      total,
      page,
      limit,
    );
  }

  async adminGet(id: string) {
    const order = await this.prisma.order.findUnique({
      where: { id },
      include: {
        items: true,
        user: { select: { id: true, email: true, name: true, phone: true } },
      },
    });
    if (!order) throw new NotFoundException('Order not found');
    return this.serializeOrder(order);
  }

  async updateStatus(id: string, status: OrderStatus) {
    const order = await this.prisma.order.findUnique({ where: { id } });
    if (!order) throw new NotFoundException('Order not found');
    if (!canTransitionOrderStatus(order.status, status)) {
      throw new BadRequestException(
        `Forbidden status transition: ${order.status} → ${status}`,
      );
    }
    const updated = await this.prisma.order.update({
      where: { id },
      data: { status },
      include: { items: true },
    });
    return this.serializeOrder(updated);
  }

  private serializeOrder(order: {
    id: string;
    publicNumber: string;
    userId: string;
    addressSnapshot: unknown;
    phone: string;
    comment: string | null;
    status: OrderStatus;
    subtotal: Prisma.Decimal | number;
    deliveryFee: Prisma.Decimal | number;
    total: Prisma.Decimal | number;
    idempotencyKey: string;
    createdAt: Date;
    updatedAt: Date;
    items: Array<{
      id: string;
      productId: string | null;
      productNameSnapshot: string;
      unitPrice: Prisma.Decimal | number;
      quantity: number;
      lineTotal: Prisma.Decimal | number;
    }>;
    user?: unknown;
  }) {
    return {
      ...order,
      subtotal: moneyToNumber(order.subtotal),
      deliveryFee: moneyToNumber(order.deliveryFee),
      total: moneyToNumber(order.total),
      items: order.items.map((i) => ({
        ...i,
        unitPrice: moneyToNumber(i.unitPrice),
        lineTotal: moneyToNumber(i.lineTotal),
      })),
    };
  }

  private async nextPublicNumber(): Promise<string> {
    const count = await this.prisma.order.count();
    const n = count + 1;
    return `SZ-${String(n).padStart(6, '0')}`;
  }
}
