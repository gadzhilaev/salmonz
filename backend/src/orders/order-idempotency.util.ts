import { createHash } from 'crypto';

/** Canonical payload fingerprint for idempotency reuse checks. */
export function orderIdempotencyHash(dto: {
  addressId: string;
  phone: string;
  comment?: string | null;
  items: Array<{ productId: string; quantity: number }>;
}): string {
  const items = [...dto.items]
    .map((i) => ({ productId: i.productId, quantity: i.quantity }))
    .sort((a, b) => a.productId.localeCompare(b.productId));
  const canonical = {
    addressId: dto.addressId,
    phone: dto.phone.trim(),
    comment: dto.comment?.trim() ?? '',
    items,
  };
  return createHash('sha256').update(JSON.stringify(canonical)).digest('hex');
}
