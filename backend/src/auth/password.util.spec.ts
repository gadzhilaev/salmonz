import { hashPassword, verifyPassword, hashToken } from './password.util';

describe('password.util', () => {
  it('hashes and verifies with argon2id', async () => {
    const hash = await hashPassword('Secret123!');
    expect(hash).toMatch(/^\$argon2id\$/);
    await expect(verifyPassword(hash, 'Secret123!')).resolves.toBe(true);
    await expect(verifyPassword(hash, 'wrong')).resolves.toBe(false);
  });

  it('hashes refresh tokens deterministically with sha256', () => {
    const a = hashToken('token-value');
    const b = hashToken('token-value');
    const c = hashToken('other');
    expect(a).toBe(b);
    expect(a).not.toBe(c);
    expect(a).toHaveLength(64);
  });
});
