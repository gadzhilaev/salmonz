import { OrderStatus } from '../../../generated/prisma/enums';

const ALLOWED: Record<OrderStatus, readonly OrderStatus[]> = {
  [OrderStatus.NEW]: [OrderStatus.CONFIRMED, OrderStatus.CANCELLED],
  [OrderStatus.CONFIRMED]: [OrderStatus.PREPARING, OrderStatus.CANCELLED],
  [OrderStatus.PREPARING]: [OrderStatus.READY],
  [OrderStatus.READY]: [OrderStatus.DELIVERING, OrderStatus.COMPLETED],
  [OrderStatus.DELIVERING]: [OrderStatus.COMPLETED],
  [OrderStatus.COMPLETED]: [],
  [OrderStatus.CANCELLED]: [],
};

export function canTransitionOrderStatus(
  from: OrderStatus,
  to: OrderStatus,
): boolean {
  return ALLOWED[from]?.includes(to) ?? false;
}

export function assertOrderStatusTransition(
  from: OrderStatus,
  to: OrderStatus,
): void {
  if (!canTransitionOrderStatus(from, to)) {
    throw new Error(`Forbidden order status transition: ${from} → ${to}`);
  }
}

export function allowedNextStatuses(from: OrderStatus): OrderStatus[] {
  return [...(ALLOWED[from] ?? [])];
}
