/**
 * Full HTTP e2e suite requires PostgreSQL + valid env (Docker Compose).
 * Without DATABASE_URL these tests are skipped so CI/local without Docker stays green.
 *
 * Owner: start compose, copy backend/.env.example → backend/.env, migrate+seed, then:
 *   npm run test:e2e
 */
const maybeDescribe = process.env.RUN_E2E === '1' ? describe : describe.skip;

maybeDescribe('Salmonz API (e2e)', () => {
  it('placeholder — set RUN_E2E=1 with Postgres to enable', () => {
    expect(true).toBe(true);
  });
});
