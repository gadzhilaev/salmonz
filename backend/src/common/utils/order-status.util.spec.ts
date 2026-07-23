import { OrderStatus } from '../../../generated/prisma/enums';
import {
  canTransitionOrderStatus,
  assertOrderStatusTransition,
} from './order-status.util';

describe('order-status.util', () => {
  it('allows documented transitions', () => {
    expect(
      canTransitionOrderStatus(OrderStatus.NEW, OrderStatus.CONFIRMED),
    ).toBe(true);
    expect(
      canTransitionOrderStatus(OrderStatus.NEW, OrderStatus.CANCELLED),
    ).toBe(true);
    expect(
      canTransitionOrderStatus(OrderStatus.CONFIRMED, OrderStatus.PREPARING),
    ).toBe(true);
    expect(
      canTransitionOrderStatus(OrderStatus.PREPARING, OrderStatus.READY),
    ).toBe(true);
    expect(
      canTransitionOrderStatus(OrderStatus.READY, OrderStatus.DELIVERING),
    ).toBe(true);
    expect(
      canTransitionOrderStatus(OrderStatus.DELIVERING, OrderStatus.COMPLETED),
    ).toBe(true);
  });

  it('forbids terminal and illegal transitions', () => {
    expect(
      canTransitionOrderStatus(OrderStatus.COMPLETED, OrderStatus.NEW),
    ).toBe(false);
    expect(
      canTransitionOrderStatus(OrderStatus.CANCELLED, OrderStatus.CONFIRMED),
    ).toBe(false);
    expect(
      canTransitionOrderStatus(OrderStatus.NEW, OrderStatus.PREPARING),
    ).toBe(false);
    expect(
      canTransitionOrderStatus(OrderStatus.READY, OrderStatus.CANCELLED),
    ).toBe(false);
  });

  it('assert throws on forbidden transition', () => {
    expect(() =>
      assertOrderStatusTransition(OrderStatus.COMPLETED, OrderStatus.CANCELLED),
    ).toThrow(/Forbidden/);
  });
});
