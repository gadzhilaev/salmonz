import { orderIdempotencyHash } from './order-idempotency.util';

describe('orderIdempotencyHash', () => {
  it('is stable for reordered items', () => {
    const a = orderIdempotencyHash({
      addressId: 'addr-1',
      phone: '+7999',
      comment: 'x',
      items: [
        { productId: 'p2', quantity: 1 },
        { productId: 'p1', quantity: 2 },
      ],
    });
    const b = orderIdempotencyHash({
      addressId: 'addr-1',
      phone: '+7999',
      comment: 'x',
      items: [
        { productId: 'p1', quantity: 2 },
        { productId: 'p2', quantity: 1 },
      ],
    });
    expect(a).toBe(b);
  });

  it('changes when quantity differs', () => {
    const a = orderIdempotencyHash({
      addressId: 'addr-1',
      phone: '+7999',
      items: [{ productId: 'p1', quantity: 1 }],
    });
    const b = orderIdempotencyHash({
      addressId: 'addr-1',
      phone: '+7999',
      items: [{ productId: 'p1', quantity: 2 }],
    });
    expect(a).not.toBe(b);
  });
});
