/**
 * Live HTTP e2e against a running Nest server.
 * Requires: backend up on API_URL (default http://localhost:3000), seeded DB.
 * Enable with RUN_E2E=1
 */
import request from 'supertest';
import { randomUUID } from 'crypto';

const enabled = process.env.RUN_E2E === '1';
const describeE2e = enabled ? describe : describe.skip;
const api = process.env.API_URL ?? 'http://localhost:3000';

describeE2e('Salmonz live API e2e', () => {
  const suffix = randomUUID().slice(0, 8);
  const userEmail = `user_${suffix}@example.com`;
  const userPass = 'TestUserPass123!';
  let userAccess = '';
  let userRefresh = '';
  let adminAccess = '';
  let productId = '';
  let addressId = '';
  let orderId = '';

  beforeAll(async () => {
    const adminLogin = await request(api)
      .post('/api/v1/auth/login')
      .send({
        email: process.env.ADMIN_EMAIL ?? 'admin@example.com',
        password: process.env.ADMIN_PASSWORD ?? 'ChangeMeAdmin123!',
      });
    expect(adminLogin.status).toBeLessThan(300);
    adminAccess = adminLogin.body.accessToken;
    expect(adminAccess).toBeTruthy();
  }, 30000);

  it('health', async () => {
    await request(api).get('/api/v1/health/live').expect(200);
    await request(api).get('/api/v1/health').expect(200);
  });

  it('register forces USER and rejects unknown fields', async () => {
    const bad = await request(api)
      .post('/api/v1/auth/register')
      .send({
        email: userEmail,
        password: userPass,
        name: 'E2E User',
        role: 'ADMIN',
      });
    expect(bad.status).toBe(400);

    const ok = await request(api)
      .post('/api/v1/auth/register')
      .send({ email: userEmail, password: userPass, name: 'E2E User' });
    expect(ok.status).toBeLessThan(300);
    expect(ok.body.user.role).toBe('USER');
    expect(JSON.stringify(ok.body)).not.toMatch(/passwordHash|tokenHash/);
    userAccess = ok.body.accessToken;
    userRefresh = ok.body.refreshToken;
  });

  it('duplicate email fails', async () => {
    const res = await request(api)
      .post('/api/v1/auth/register')
      .send({ email: userEmail, password: userPass, name: 'X' });
    expect(res.status).toBeGreaterThanOrEqual(400);
  });

  it('login + me', async () => {
    const login = await request(api)
      .post('/api/v1/auth/login')
      .send({ email: userEmail, password: userPass });
    expect(login.status).toBeLessThan(300);
    userAccess = login.body.accessToken;
    userRefresh = login.body.refreshToken;
    const me = await request(api)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${userAccess}`)
      .expect(200);
    expect(me.body.email).toBe(userEmail.toLowerCase());
  });

  it('refresh rotation rejects reused token', async () => {
    const first = await request(api)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: userRefresh });
    expect(first.status).toBeLessThan(300);
    const old = userRefresh;
    userAccess = first.body.accessToken;
    userRefresh = first.body.refreshToken;
    const reuse = await request(api)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: old });
    expect(reuse.status).toBe(401);
  });

  it('public catalog', async () => {
    const cats = await request(api).get('/api/v1/categories').expect(200);
    const catList = Array.isArray(cats.body) ? cats.body : cats.body.data;
    expect(catList.length).toBeGreaterThan(0);
    const products = await request(api)
      .get('/api/v1/products?limit=5')
      .expect(200);
    const items = products.body.data ?? products.body.items ?? products.body;
    expect(items.length).toBeGreaterThan(0);
    productId = items[0].id;
  });

  it('user denied admin', async () => {
    await request(api)
      .post('/api/v1/admin/categories')
      .set('Authorization', `Bearer ${userAccess}`)
      .send({ name: 'Hack', slug: `hack-${suffix}` })
      .expect(403);
  });

  it('address CRUD', async () => {
    const created = await request(api)
      .post('/api/v1/addresses')
      .set('Authorization', `Bearer ${userAccess}`)
      .send({
        city: 'Москва',
        street: 'Тверская',
        house: '1',
        isDefault: true,
      });
    expect(created.status).toBeLessThan(300);
    addressId = created.body.id;
  });

  it('order server pricing + idempotency', async () => {
    const key = `idempotency-${suffix}`;
    const payload = {
      addressId,
      phone: '+79001234567',
      comment: 'e2e',
      idempotencyKey: key,
      items: [{ productId, quantity: 2 }],
    };
    const first = await request(api)
      .post('/api/v1/orders')
      .set('Authorization', `Bearer ${userAccess}`)
      .send(payload);
    expect(first.status).toBeLessThan(300);
    orderId = first.body.id;
    expect(Number(first.body.total)).toBeGreaterThan(0);
    const second = await request(api)
      .post('/api/v1/orders')
      .set('Authorization', `Bearer ${userAccess}`)
      .send(payload);
    expect(second.status).toBeLessThan(300);
    expect(second.body.id).toBe(orderId);
  });

  it('admin status transitions', async () => {
    const ok = await request(api)
      .patch(`/api/v1/admin/orders/${orderId}/status`)
      .set('Authorization', `Bearer ${adminAccess}`)
      .send({ status: 'CONFIRMED' });
    expect(ok.status).toBeLessThan(300);
    const bad = await request(api)
      .patch(`/api/v1/admin/orders/${orderId}/status`)
      .set('Authorization', `Bearer ${adminAccess}`)
      .send({ status: 'NEW' });
    expect(bad.status).toBeGreaterThanOrEqual(400);
  });

  it('support message', async () => {
    const msg = await request(api)
      .post('/api/v1/support')
      .set('Authorization', `Bearer ${userAccess}`)
      .send({ message: 'Help e2e', subject: 'Test' });
    expect(msg.status).toBeLessThan(300);
  });

  it('logout', async () => {
    const res = await request(api)
      .post('/api/v1/auth/logout')
      .set('Authorization', `Bearer ${userAccess}`)
      .send({ refreshToken: userRefresh });
    expect(res.status).toBeLessThan(300);
  });
});
