import { cookies } from 'next/headers';
import { randomBytes, createHash, timingSafeEqual } from 'crypto';
import {
  ACCESS_COOKIE,
  CSRF_COOKIE,
  REFRESH_COOKIE,
} from './auth-constants';

export {
  ACCESS_COOKIE,
  CSRF_COOKIE,
  CSRF_HEADER,
  REFRESH_COOKIE,
} from './auth-constants';

const isProd = process.env.NODE_ENV === 'production';

export function backendBaseUrl(): string {
  return (
    process.env.API_BASE_URL?.replace(/\/+$/, '') ??
    process.env.NEXT_PUBLIC_API_BASE_URL?.replace(/\/+$/, '') ??
    'http://127.0.0.1:3000'
  );
}

export function cookieSecure(): boolean {
  if (process.env.COOKIE_SECURE === 'true') return true;
  if (process.env.COOKIE_SECURE === 'false') return false;
  return isProd;
}

export function cookieSameSite(): 'lax' | 'strict' | 'none' {
  const v = (process.env.COOKIE_SAMESITE ?? 'lax').toLowerCase();
  if (v === 'strict' || v === 'none' || v === 'lax') return v;
  return 'lax';
}

export function accessCookieOptions(maxAgeSec = 60 * 15) {
  return {
    httpOnly: true,
    secure: cookieSecure(),
    sameSite: cookieSameSite(),
    path: '/',
    maxAge: maxAgeSec,
  } as const;
}

export function refreshCookieOptions(maxAgeSec = 60 * 60 * 24 * 30) {
  return {
    httpOnly: true,
    secure: cookieSecure(),
    sameSite: cookieSameSite(),
    path: '/',
    maxAge: maxAgeSec,
  } as const;
}

export function csrfCookieOptions(maxAgeSec = 60 * 60 * 24 * 30) {
  return {
    httpOnly: false,
    secure: cookieSecure(),
    sameSite: cookieSameSite(),
    path: '/',
    maxAge: maxAgeSec,
  } as const;
}

export function newCsrfToken(): string {
  return randomBytes(32).toString('hex');
}

export function hashPayload(value: unknown): string {
  return createHash('sha256').update(JSON.stringify(value)).digest('hex');
}

export function safeEqual(a: string, b: string): boolean {
  const ba = Buffer.from(a);
  const bb = Buffer.from(b);
  if (ba.length !== bb.length) return false;
  return timingSafeEqual(ba, bb);
}

export async function readSessionCookies() {
  const jar = await cookies();
  return {
    accessToken: jar.get(ACCESS_COOKIE)?.value ?? null,
    refreshToken: jar.get(REFRESH_COOKIE)?.value ?? null,
    csrf: jar.get(CSRF_COOKIE)?.value ?? null,
  };
}
