import {
  calcDeliveryFee,
  calcLineTotal,
  calcOrderMoney,
  DELIVERY_FEE_AMOUNT,
  formatMoneyString,
  FREE_DELIVERY_THRESHOLD,
} from './money.util';

describe('money.util', () => {
  it('formats money as fixed 2-decimal string', () => {
    expect(formatMoneyString(858)).toBe('858.00');
    expect(formatMoneyString(249)).toBe('249.00');
  });

  it('calculates line totals', () => {
    expect(calcLineTotal(199.5, 2)).toBe(399);
  });

  it('applies free delivery at threshold', () => {
    expect(calcDeliveryFee(FREE_DELIVERY_THRESHOLD - 1)).toBe(
      DELIVERY_FEE_AMOUNT,
    );
    expect(calcDeliveryFee(FREE_DELIVERY_THRESHOLD)).toBe(0);
    expect(calcDeliveryFee(FREE_DELIVERY_THRESHOLD + 100)).toBe(0);
  });

  it('computes order money breakdown', () => {
    const result = calcOrderMoney([
      { unitPrice: 500, quantity: 2 },
      { unitPrice: 400, quantity: 1 },
    ]);
    expect(result.subtotal).toBe(1400);
    expect(result.deliveryFee).toBe(249);
    expect(result.total).toBe(1649);

    const free = calcOrderMoney([{ unitPrice: 750, quantity: 2 }]);
    expect(free.subtotal).toBe(1500);
    expect(free.deliveryFee).toBe(0);
    expect(free.total).toBe(1500);
  });
});
