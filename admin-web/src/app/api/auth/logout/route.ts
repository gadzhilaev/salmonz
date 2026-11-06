import { NextRequest, NextResponse } from 'next/server';
import { nestLogout } from '@/lib/backend';
import {
  ACCESS_COOKIE,
  CSRF_COOKIE,
  CSRF_HEADER,
  REFRESH_COOKIE,
  accessCookieOptions,
  csrfCookieOptions,
  refreshCookieOptions,
  safeEqual,
} from '@/lib/session';

export async function POST(req: NextRequest) {
  const csrfCookie = req.cookies.get(CSRF_COOKIE)?.value;
  const csrfHeader = req.headers.get(CSRF_HEADER);
  if (!csrfCookie || !csrfHeader || !safeEqual(csrfCookie, csrfHeader)) {
    return NextResponse.json({ message: 'Invalid CSRF token' }, { status: 403 });
  }

  const refresh = req.cookies.get(REFRESH_COOKIE)?.value;
  if (refresh) {
    try {
      await nestLogout(refresh);
    } catch {
      // still clear cookies
    }
  }

  const res = NextResponse.json({ ok: true });
  res.cookies.set(ACCESS_COOKIE, '', { ...accessCookieOptions(0), maxAge: 0 });
  res.cookies.set(REFRESH_COOKIE, '', { ...refreshCookieOptions(0), maxAge: 0 });
  res.cookies.set(CSRF_COOKIE, '', { ...csrfCookieOptions(0), maxAge: 0 });
  return res;
}
