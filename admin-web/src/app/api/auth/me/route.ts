import { NextResponse } from 'next/server';
import { nestFetch, nestRefresh } from '@/lib/backend';
import {
  ACCESS_COOKIE,
  REFRESH_COOKIE,
  accessCookieOptions,
  readSessionCookies,
  refreshCookieOptions,
} from '@/lib/session';

export async function GET() {
  const session = await readSessionCookies();
  let access = session.accessToken;
  let refresh = session.refreshToken;

  async function loadMe(token: string) {
    return nestFetch('/auth/me', { method: 'GET' }, token);
  }

  if (!access && !refresh) {
    return NextResponse.json({ authenticated: false }, { status: 401 });
  }

  let res = access ? await loadMe(access) : null;
  if ((!res || res.status === 401) && refresh) {
    try {
      const rotated = await nestRefresh(refresh);
      access = rotated.accessToken;
      refresh = rotated.refreshToken;
      res = await loadMe(access);
      const out = NextResponse.json(
        res.ok
          ? { authenticated: true, user: await res.json() }
          : { authenticated: false },
        { status: res.ok ? 200 : 401 },
      );
      out.cookies.set(ACCESS_COOKIE, access, accessCookieOptions());
      out.cookies.set(REFRESH_COOKIE, refresh, refreshCookieOptions());
      return out;
    } catch {
      return NextResponse.json({ authenticated: false }, { status: 401 });
    }
  }

  if (!res || !res.ok) {
    return NextResponse.json({ authenticated: false }, { status: 401 });
  }
  const user = await res.json();
  if (user?.role !== 'ADMIN') {
    return NextResponse.json({ authenticated: false }, { status: 403 });
  }
  return NextResponse.json({ authenticated: true, user });
}
