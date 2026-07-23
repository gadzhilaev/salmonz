export type MoneyLike =
  number | string | { toNumber(): number; toFixed(dp?: number): string };

export function moneyToNumber(value: MoneyLike): number {
  const n =
    typeof value === 'number'
      ? value
      : typeof value === 'string'
        ? Number(value)
        : value.toNumber();
  return Math.round((n + Number.EPSILON) * 100) / 100;
}

export function moneyToString(value: MoneyLike): string {
  return moneyToNumber(value).toFixed(2);
}

export function addMoney(a: MoneyLike, b: MoneyLike): number {
  return moneyToNumber(moneyToNumber(a) + moneyToNumber(b));
}

export function mulMoney(unit: MoneyLike, quantity: number): number {
  return moneyToNumber(moneyToNumber(unit) * quantity);
}
