import { NextRequest, NextResponse } from 'next/server';
import { ACCESS_COOKIE, REFRESH_COOKIE } from './lib/auth-constants';

const PUBLIC_PREFIXES = ['/login', '/legal', '/api/auth'];

export function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl;
  if (
    PUBLIC_PREFIXES.some(
      (p) => pathname === p || pathname.startsWith(`${p}/`),
    ) ||
    pathname.startsWith('/_next') ||
    pathname === '/favicon.ico'
  ) {
    return NextResponse.next();
  }

  // Proxy and other API routes handle their own auth.
  if (pathname.startsWith('/api/')) {
    return NextResponse.next();
  }

  const hasSession =
    Boolean(req.cookies.get(ACCESS_COOKIE)?.value) ||
    Boolean(req.cookies.get(REFRESH_COOKIE)?.value);

  if (!hasSession && pathname !== '/') {
    const url = req.nextUrl.clone();
    url.pathname = '/login';
    url.searchParams.set('next', pathname);
    return NextResponse.redirect(url);
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};
