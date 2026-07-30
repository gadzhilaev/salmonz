/**
 * Delivery fee rule (RUB):
 * - free delivery when subtotal >= 1500
 * - otherwise flat fee of 249
 */
export const FREE_DELIVERY_THRESHOLD = 1500;
export const DELIVERY_FEE_AMOUNT = 249;

export type OrderLineInput = {
  unitPrice: number;
  quantity: number;
};

export type OrderMoneyBreakdown = {
  lines: Array<{ unitPrice: number; quantity: number; lineTotal: number }>;
  subtotal: number;
  deliveryFee: number;
  total: number;
};

export function calcLineTotal(unitPrice: number, quantity: number): number {
  return roundMoney(unitPrice * quantity);
}

export function calcDeliveryFee(subtotal: number): number {
  return subtotal >= FREE_DELIVERY_THRESHOLD ? 0 : DELIVERY_FEE_AMOUNT;
}

export function calcOrderMoney(items: OrderLineInput[]): OrderMoneyBreakdown {
  const lines = items.map((item) => ({
    unitPrice: roundMoney(item.unitPrice),
    quantity: item.quantity,
    lineTotal: calcLineTotal(item.unitPrice, item.quantity),
  }));
  const subtotal = roundMoney(lines.reduce((sum, l) => sum + l.lineTotal, 0));
  const deliveryFee = calcDeliveryFee(subtotal);
  const total = roundMoney(subtotal + deliveryFee);
  return { lines, subtotal, deliveryFee, total };
}

export function roundMoney(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

export function formatMoneyString(n: number): string {
  return n.toFixed(2);
}
