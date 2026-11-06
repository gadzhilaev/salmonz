/**
 * Concurrent refresh / status checks against a live Postgres.
 * Enable with RUN_CONCURRENT=1 and a reachable API (default 127.0.0.1:3000).
 */
import request from 'supertest';
import { randomUUID } from 'crypto';

const enabled = process.env.RUN_CONCURRENT === '1';
const describeConcurrent = enabled ? describe : describe.skip;
const api = process.env.API_URL ?? 'http://127.0.0.1:3000';

describeConcurrent('concurrent auth refresh (live)', () => {
  it('only one concurrent refresh succeeds with the same token', async () => {
    const email = `conc_${randomUUID().slice(0, 8)}@example.com`;
    const password = 'ConcPass123!';
    const reg = await request(api).post('/api/v1/auth/register').send({
      email,
      password,
      name: 'Conc User',
    });
    expect(reg.status).toBeLessThan(300);
    const refreshToken = reg.body.refreshToken as string;
    expect(refreshToken).toBeTruthy();

    const results = await Promise.all(
      Array.from({ length: 8 }, () =>
        request(api)
          .post('/api/v1/auth/refresh')
          .send({ refreshToken })
          .then((r) => r.status)
          .catch(() => 500),
      ),
    );

    const ok = results.filter((s) => s < 300).length;
    const unauthorized = results.filter((s) => s === 401).length;
    expect(ok).toBe(1);
    expect(unauthorized).toBe(results.length - 1);
  }, 30000);
});
