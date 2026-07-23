import { calcOrderMoney } from '../common/utils/money.util';
import { canTransitionOrderStatus } from '../common/utils/order-status.util';
import { OrderStatus } from '../../generated/prisma/enums';

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
