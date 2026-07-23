import { BadRequestException } from '@nestjs/common';
import { calcOrderMoney } from '../common/utils/money.util';
import { canTransitionOrderStatus } from '../common/utils/order-status.util';
import { OrderStatus } from '../../generated/prisma/enums';
import { OrdersService } from './orders.service';

jest.mock('../prisma/prisma.service', () => ({
  PrismaService: class PrismaService {},
}));

jest.mock('../../generated/prisma/client', () => ({
  Prisma: {
    PrismaClientKnownRequestError: class PrismaClientKnownRequestError extends Error {
      code = '';
    },
  },
}));

describe('Orders domain rules', () => {
  it('calculates delivery fee and totals server-side', () => {
    const small = calcOrderMoney([
      { unitPrice: 400, quantity: 2 },
      { unitPrice: 200, quantity: 1 },
    ]);
    expect(small.subtotal).toBe(1000);
    expect(small.deliveryFee).toBe(249);
    expect(small.total).toBe(1249);

    const freeDelivery = calcOrderMoney([{ unitPrice: 800, quantity: 2 }]);
    expect(freeDelivery.subtotal).toBe(1600);
    expect(freeDelivery.deliveryFee).toBe(0);
    expect(freeDelivery.total).toBe(1600);
  });

  it('enforces status transition rules', () => {
    expect(
      canTransitionOrderStatus(OrderStatus.NEW, OrderStatus.CONFIRMED),
    ).toBe(true);
    expect(
      canTransitionOrderStatus(OrderStatus.COMPLETED, OrderStatus.NEW),
    ).toBe(false);
    expect(
      canTransitionOrderStatus(OrderStatus.CANCELLED, OrderStatus.CONFIRMED),
    ).toBe(false);
  });
});

describe('OrdersService.quote', () => {
  const userId = 'user-1';

  function makeService(products: Array<{
    id: string;
    name: string;
    price: number;
    isAvailable: boolean;
  }>) {
    const prisma = {
      product: {
        findMany: jest.fn(async ({ where }: { where: { id: { in: string[] } } }) =>
          products.filter((p) => where.id.in.includes(p.id)),
        ),
      },
      order: {
        findUnique: jest.fn(),
        create: jest.fn(),
        count: jest.fn(),
      },
    };
    return {
      service: new OrdersService(prisma as never),
      prisma,
    };
  }

  it('quotes money with delivery fee for small subtotal', async () => {
    const { service, prisma } = makeService([
      { id: 'p1', name: 'Roll A', price: 429, isAvailable: true },
    ]);

    const quote = await service.quote(userId, {
      items: [{ productId: 'p1', quantity: 2 }],
    });

    expect(prisma.order.create).not.toHaveBeenCalled();
    expect(quote).toEqual({
      items: [
        {
          productId: 'p1',
          productName: 'Roll A',
          unitPrice: '429.00',
          quantity: 2,
          lineTotal: '858.00',
          isAvailable: true,
        },
      ],
      subtotal: '858.00',
      deliveryFee: '249.00',
      total: '1107.00',
      currency: 'RUB',
      freeDeliveryThreshold: 1500,
      deliveryFeeAmount: 249,
    });
  });

  it('quotes free delivery when available subtotal >= 1500', async () => {
    const { service } = makeService([
      { id: 'p1', name: 'Set', price: 800, isAvailable: true },
    ]);

    const quote = await service.quote(userId, {
      items: [{ productId: 'p1', quantity: 2 }],
    });

    expect(quote.subtotal).toBe('1600.00');
    expect(quote.deliveryFee).toBe('0.00');
    expect(quote.total).toBe('1600.00');
  });

  it('includes unavailable items but excludes them from totals', async () => {
    const { service, prisma } = makeService([
      { id: 'p1', name: 'Available', price: 500, isAvailable: true },
      { id: 'p2', name: 'Sold out', price: 900, isAvailable: false },
    ]);

    const quote = await service.quote(userId, {
      items: [
        { productId: 'p1', quantity: 1 },
        { productId: 'p2', quantity: 2 },
      ],
    });

    expect(prisma.order.create).not.toHaveBeenCalled();
    expect(quote.items).toEqual([
      {
        productId: 'p1',
        productName: 'Available',
        unitPrice: '500.00',
        quantity: 1,
        lineTotal: '500.00',
        isAvailable: true,
      },
      {
        productId: 'p2',
        productName: 'Sold out',
        unitPrice: '900.00',
        quantity: 2,
        lineTotal: '1800.00',
        isAvailable: false,
      },
    ]);
    expect(quote.subtotal).toBe('500.00');
    expect(quote.deliveryFee).toBe('249.00');
    expect(quote.total).toBe('749.00');
  });

  it('returns zero totals when all items are unavailable', async () => {
    const { service } = makeService([
      { id: 'p2', name: 'Sold out', price: 900, isAvailable: false },
    ]);

    const quote = await service.quote(userId, {
      items: [{ productId: 'p2', quantity: 1 }],
    });

    expect(quote.items[0].isAvailable).toBe(false);
    expect(quote.subtotal).toBe('0.00');
    expect(quote.deliveryFee).toBe('0.00');
    expect(quote.total).toBe('0.00');
  });

  it('throws when a product is missing', async () => {
    const { service } = makeService([
      { id: 'p1', name: 'Available', price: 500, isAvailable: true },
    ]);

    await expect(
      service.quote(userId, {
        items: [
          { productId: 'p1', quantity: 1 },
          { productId: 'missing', quantity: 1 },
        ],
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });
});
