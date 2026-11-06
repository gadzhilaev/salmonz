import { NextRequest, NextResponse } from 'next/server';
import { nestLogin } from '@/lib/backend';
import {
  ACCESS_COOKIE,
  CSRF_COOKIE,
  CSRF_HEADER,
  REFRESH_COOKIE,
  accessCookieOptions,
  csrfCookieOptions,
  newCsrfToken,
  refreshCookieOptions,
  safeEqual,
} from '@/lib/session';

export async function POST(req: NextRequest) {
  const csrfCookie = req.cookies.get(CSRF_COOKIE)?.value;
  const csrfHeader = req.headers.get(CSRF_HEADER);
  if (!csrfCookie || !csrfHeader || !safeEqual(csrfCookie, csrfHeader)) {
    return NextResponse.json({ message: 'Invalid CSRF token' }, { status: 403 });
  }

  let body: { email?: string; password?: string };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ message: 'Invalid JSON' }, { status: 400 });
  }

  const email = body.email?.trim() ?? '';
  const password = body.password ?? '';
  if (!email || !password) {
    return NextResponse.json({ message: 'Email and password required' }, { status: 400 });
  }

  try {
    const data = await nestLogin(email, password);
    if (data.user.role !== 'ADMIN') {
      return NextResponse.json(
        { message: 'Admin role required' },
        { status: 403 },
      );
    }

    const csrf = newCsrfToken();
    const res = NextResponse.json({
      user: {
        id: data.user.id,
        email: data.user.email,
        name: data.user.name,
        role: data.user.role,
      },
    });
    res.cookies.set(ACCESS_COOKIE, data.accessToken, accessCookieOptions());
    res.cookies.set(REFRESH_COOKIE, data.refreshToken, refreshCookieOptions());
    res.cookies.set(CSRF_COOKIE, csrf, csrfCookieOptions());
    return res;
  } catch (e) {
    return NextResponse.json(
      { message: e instanceof Error ? e.message : 'Login failed' },
      { status: 401 },
    );
  }
}
