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
import {
  calcLineTotal,
  calcOrderMoney,
  DELIVERY_FEE_AMOUNT,
  formatMoneyString,
  FREE_DELIVERY_THRESHOLD,
  roundMoney,
} from '../common/utils/money.util';
import { canTransitionOrderStatus } from '../common/utils/order-status.util';
import { PrismaService } from '../prisma/prisma.service';
import {
  CreateOrderDto,
  CreateOrderItemDto,
  QuoteOrderDto,
} from './dto/order.dto';

type PricedLine = {
  productId: string;
  productName: string;
  unitPrice: number;
  quantity: number;
  isAvailable: boolean;
};

@Injectable()
export class OrdersService {
  constructor(private readonly prisma: PrismaService) {}

  async quote(_userId: string, dto: QuoteOrderDto) {
    const priced = await this.buildPricedLines(dto.items);
    const available = priced.filter((line) => line.isAvailable);
    const money =
      available.length > 0
        ? calcOrderMoney(available)
        : { subtotal: 0, deliveryFee: 0, total: 0, lines: [] };

    return {
      items: priced.map((line) => ({
        productId: line.productId,
        productName: line.productName,
        unitPrice: formatMoneyString(roundMoney(line.unitPrice)),
        quantity: line.quantity,
        lineTotal: formatMoneyString(
          calcLineTotal(line.unitPrice, line.quantity),
        ),
        isAvailable: line.isAvailable,
      })),
      subtotal: formatMoneyString(money.subtotal),
      deliveryFee: formatMoneyString(money.deliveryFee),
      total: formatMoneyString(money.total),
      currency: 'RUB',
      freeDeliveryThreshold: FREE_DELIVERY_THRESHOLD,
      deliveryFeeAmount: DELIVERY_FEE_AMOUNT,
    };
  }

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

    const priced = await this.buildPricedLines(dto.items);
    const unavailable = priced.filter((line) => !line.isAvailable);
    if (unavailable.length) {
      throw new BadRequestException(
        `Unavailable products: ${unavailable.map((p) => p.productName).join(', ')}`,
      );
    }

    const money = calcOrderMoney(priced);
    const publicNumber = this.nextPublicNumber();

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
            create: priced.map((line, idx) => ({
              productId: line.productId,
              productNameSnapshot: line.productName,
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

  private async buildPricedLines(
    items: CreateOrderItemDto[],
  ): Promise<PricedLine[]> {
    const productIds = [...new Set(items.map((i) => i.productId))];
    const products = await this.prisma.product.findMany({
      where: { id: { in: productIds } },
    });
    if (products.length !== productIds.length) {
      throw new BadRequestException('One or more products not found');
    }

    const productMap = new Map(products.map((p) => [p.id, p]));
    return items.map((item) => {
      const product = productMap.get(item.productId)!;
      return {
        productId: product.id,
        productName: product.name,
        unitPrice: moneyToNumber(product.price),
        quantity: item.quantity,
        isAvailable: product.isAvailable,
      };
    });
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

  private nextPublicNumber(): string {
    // Time-based + random suffix avoids collisions under concurrent creates.
    const stamp = Date.now().toString(36).toUpperCase();
    const rand = Math.floor(Math.random() * 36 ** 4)
      .toString(36)
      .toUpperCase()
      .padStart(4, '0');
    return `SZ-${stamp}-${rand}`;
  }
}
