#!/usr/bin/env node
/**
 * Smoke: CSRF + ADMIN login + USER denied + proxy + logout.
 * Requires admin-web on :3001 and Nest on :3000.
 */
import { CookieJar } from './cookie-jar.mjs';

const BASE = process.env.ADMIN_WEB_URL ?? 'http://127.0.0.1:3001';

async function main() {
  const jar = new CookieJar();
  const csrfRes = await jar.fetch(`${BASE}/api/auth/csrf`);
  const { csrfToken } = await csrfRes.json();
  if (!csrfToken) throw new Error('no csrf');

  const bad = await jar.fetch(`${BASE}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: 'admin@example.com',
      password: 'ChangeMeAdmin123!',
    }),
  });
  if (bad.status !== 403) throw new Error(`expected CSRF 403, got ${bad.status}`);

  const login = await jar.fetch(`${BASE}/api/auth/login`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-csrf-token': csrfToken,
    },
    body: JSON.stringify({
      email: 'admin@example.com',
      password: 'ChangeMeAdmin123!',
    }),
  });
  const loginBody = await login.json();
  if (login.status !== 200) throw new Error(`login ${login.status} ${JSON.stringify(loginBody)}`);
  if (loginBody.accessToken || loginBody.refreshToken) {
    throw new Error('tokens leaked in login JSON');
  }
  if (!jar.has('salmonz_admin_at') || !jar.has('salmonz_admin_rt')) {
    throw new Error('missing HttpOnly cookies');
  }

  const csrf2 = jar.get('salmonz_admin_csrf');
  const orders = await jar.fetch(`${BASE}/api/proxy/admin/orders?limit=1`, {
    headers: { 'x-csrf-token': csrf2 },
  });
  if (orders.status !== 200) throw new Error(`orders ${orders.status}`);

  const userJar = new CookieJar();
  const uCsrf = await (await userJar.fetch(`${BASE}/api/auth/csrf`)).json();
  const userLogin = await userJar.fetch(`${BASE}/api/auth/login`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-csrf-token': uCsrf.csrfToken,
    },
    body: JSON.stringify({ email: 't@test.ru', password: '12345678' }),
  });
  if (userLogin.status !== 403) {
    throw new Error(`USER should be 403, got ${userLogin.status}`);
  }

  await jar.fetch(`${BASE}/api/auth/logout`, {
    method: 'POST',
    headers: { 'x-csrf-token': csrf2 },
  });

  console.log('admin-web auth smoke OK');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
