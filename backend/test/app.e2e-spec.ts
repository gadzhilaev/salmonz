/**
 * Live HTTP e2e against a running Nest server.
 * Requires: backend up on API_URL (default http://localhost:3000), seeded DB.
 * Enable with RUN_E2E=1
 */
import request from 'supertest';
import { randomUUID } from 'crypto';
import {
  DeleteObjectCommand,
  HeadBucketCommand,
  S3Client,
} from '@aws-sdk/client-s3';

const enabled = process.env.RUN_E2E === '1';
const describeE2e = enabled ? describe : describe.skip;
const s3Enabled = enabled && process.env.STORAGE_DRIVER === 's3';
const describeS3 = s3Enabled ? describe : describe.skip;
// Prefer IPv4: on Windows `localhost` can resolve to ::1 and fail while Nest listens on 127.0.0.1.
const api = process.env.API_URL ?? 'http://127.0.0.1:3000';

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
    await request(api).get('/api/v1/health/ready').expect(200);
  });

  it('register forces USER and rejects unknown fields', async () => {
    const bad = await request(api).post('/api/v1/auth/register').send({
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

  it('order quote delivery fee and no side effects', async () => {
    const productsRes = await request(api)
      .get('/api/v1/products?limit=20')
      .expect(200);
    const catalog =
      productsRes.body.data ?? productsRes.body.items ?? productsRes.body;
    expect(catalog.length).toBeGreaterThan(0);
    const product =
      catalog.find((p: { id: string }) => p.id === productId) ?? catalog[0];
    productId = product.id;
    const unitPrice = Number(product.price);
    expect(unitPrice).toBeGreaterThan(0);

    const smallQty = 1;
    expect(unitPrice * smallQty).toBeLessThan(1500);

    const beforeOrders = await request(api)
      .get('/api/v1/orders')
      .set('Authorization', `Bearer ${userAccess}`)
      .expect(200);
    const countBefore =
      beforeOrders.body.total ?? beforeOrders.body.data?.length ?? 0;

    const smallQuote = await request(api)
      .post('/api/v1/orders/quote')
      .set('Authorization', `Bearer ${userAccess}`)
      .send({ items: [{ productId, quantity: smallQty }] });
    expect(smallQuote.status).toBeLessThan(300);
    expect(smallQuote.body.deliveryFee).toBe('249.00');
    expect(smallQuote.body.currency).toBe('RUB');
    expect(smallQuote.body.freeDeliveryThreshold).toBe(1500);
    expect(smallQuote.body.deliveryFeeAmount).toBe(249);

    const freeQty = Math.ceil(1500 / unitPrice);
    const freeQuote = await request(api)
      .post('/api/v1/orders/quote')
      .set('Authorization', `Bearer ${userAccess}`)
      .send({ items: [{ productId, quantity: freeQty }] });
    expect(freeQuote.status).toBeLessThan(300);
    expect(Number(freeQuote.body.subtotal)).toBeGreaterThanOrEqual(1500);
    expect(freeQuote.body.deliveryFee).toBe('0.00');

    const afterOrders = await request(api)
      .get('/api/v1/orders')
      .set('Authorization', `Bearer ${userAccess}`)
      .expect(200);
    const countAfter =
      afterOrders.body.total ?? afterOrders.body.data?.length ?? 0;
    expect(countAfter).toBe(countBefore);
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

  it('rejects unauthenticated protected routes', async () => {
    await request(api).get('/api/v1/auth/me').expect(401);
    await request(api).get('/api/v1/orders').expect(401);
    await request(api).get('/api/v1/admin/users').expect(401);
  });

  it('rejects client price override fields on order create', async () => {
    const res = await request(api)
      .post('/api/v1/orders')
      .set('Authorization', `Bearer ${userAccess}`)
      .send({
        addressId,
        phone: '+79001234567',
        idempotencyKey: `price-hack-${suffix}`,
        total: 1,
        price: 1,
        items: [{ productId, quantity: 1, unitPrice: 1 }],
      });
    expect(res.status).toBe(400);
  });

  it('avatar upload accepts png and rejects non-image', async () => {
    // Minimal 1x1 PNG
    const png = Buffer.from(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      'base64',
    );
    const ok = await request(api)
      .post('/api/v1/users/me/avatar')
      .set('Authorization', `Bearer ${userAccess}`)
      .attach('file', png, { filename: 'dot.png', contentType: 'image/png' });
    expect(ok.status).toBeLessThan(300);
    expect(ok.body.avatarUrl || ok.body.avatarKey || ok.body.user).toBeTruthy();

    const bad = await request(api)
      .post('/api/v1/users/me/avatar')
      .set('Authorization', `Bearer ${userAccess}`)
      .attach(
        'file',
        Buffer.from('<svg xmlns="http://www.w3.org/2000/svg"></svg>'),
        {
          filename: 'x.svg',
          contentType: 'image/svg+xml',
        },
      );
    expect(bad.status).toBeGreaterThanOrEqual(400);
  });

  it('admin product image upload', async () => {
    const png = Buffer.from(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      'base64',
    );
    const res = await request(api)
      .post('/api/v1/admin/uploads/product')
      .set('Authorization', `Bearer ${adminAccess}`)
      .attach('file', png, { filename: 'p.png', contentType: 'image/png' });
    expect(res.status).toBeLessThan(300);
    expect(res.body.url || res.body.key).toBeTruthy();
  });

  it('logout', async () => {
    const res = await request(api)
      .post('/api/v1/auth/logout')
      .set('Authorization', `Bearer ${userAccess}`)
      .send({ refreshToken: userRefresh });
    expect(res.status).toBeLessThan(300);
  });
});

describeS3('S3-backed upload e2e', () => {
  const bucket = process.env.S3_BUCKET ?? 'salmonz';
  const endpoint = process.env.S3_ENDPOINT;
  const uploadedKeys: string[] = [];
  const s3 = new S3Client({
    endpoint,
    region: process.env.S3_REGION ?? 'us-east-1',
    forcePathStyle: process.env.S3_FORCE_PATH_STYLE !== 'false',
    credentials: {
      accessKeyId: process.env.S3_ACCESS_KEY ?? 'minioadmin',
      secretAccessKey: process.env.S3_SECRET_KEY ?? 'minioadmin',
    },
  });

  afterAll(async () => {
    await Promise.allSettled(
      uploadedKeys.map((Key) =>
        s3.send(new DeleteObjectCommand({ Bucket: bucket, Key })),
      ),
    );
  });

  it('uses a ready MinIO bucket for validated, publicly retrievable uploads', async () => {
    expect(endpoint).toBeTruthy();

    await request(api).get('/api/v1/health/live').expect(200);
    const minioHealth = await fetch(
      new URL('/minio/health/live', endpoint).toString(),
    );
    expect(minioHealth.ok).toBe(true);

    await expect(
      s3.send(new HeadBucketCommand({ Bucket: bucket })),
    ).resolves.toBeDefined();

    const adminLogin = await request(api)
      .post('/api/v1/auth/login')
      .send({
        email: process.env.ADMIN_EMAIL ?? 'admin@example.com',
        password: process.env.ADMIN_PASSWORD ?? 'ChangeMeAdmin123!',
      })
      .expect(201);
    const adminAccess = adminLogin.body.accessToken;
    expect(adminAccess).toBeTruthy();

    const png = Buffer.from(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      'base64',
    );
    const uploaded = await request(api)
      .post('/api/v1/admin/uploads/product')
      .set('Authorization', `Bearer ${adminAccess}`)
      .attach('file', png, { filename: 's3-e2e.png', contentType: 'image/png' })
      .expect(201);
    const uploadedKey: unknown = uploaded.body.key;
    const uploadedUrl: unknown = uploaded.body.url;
    expect(typeof uploadedKey).toBe('string');
    expect(typeof uploadedUrl).toBe('string');
    if (typeof uploadedKey !== 'string' || typeof uploadedUrl !== 'string') {
      throw new Error('Upload response did not include a key and public URL');
    }
    uploadedKeys.push(uploadedKey);

    const object = await fetch(uploadedUrl);
    expect(object.ok).toBe(true);
    expect(await object.arrayBuffer()).toEqual(
      png.buffer.slice(png.byteOffset, png.byteOffset + png.byteLength),
    );

    const invalid = await request(api)
      .post('/api/v1/admin/uploads/product')
      .set('Authorization', `Bearer ${adminAccess}`)
      .attach('file', Buffer.from('not an image'), {
        filename: 'invalid.txt',
        contentType: 'text/plain',
      });
    expect(invalid.status).toBeGreaterThanOrEqual(400);

    const oversized = await request(api)
      .post('/api/v1/admin/uploads/product')
      .set('Authorization', `Bearer ${adminAccess}`)
      .attach('file', Buffer.alloc(5 * 1024 * 1024 + 1), {
        filename: 'oversized.png',
        contentType: 'image/png',
      });
    expect(oversized.status).toBeGreaterThanOrEqual(400);
  }, 30000);
});
