import { NextRequest, NextResponse } from 'next/server';
import { nestFetch, nestRefresh } from '@/lib/backend';
import {
  ACCESS_COOKIE,
  CSRF_COOKIE,
  CSRF_HEADER,
  REFRESH_COOKIE,
  accessCookieOptions,
  refreshCookieOptions,
  safeEqual,
} from '@/lib/session';

export const runtime = 'nodejs';

type Ctx = { params: Promise<{ path: string[] }> };

function assertCsrf(req: NextRequest): NextResponse | null {
  if (req.method === 'GET' || req.method === 'HEAD') return null;
  const csrfCookie = req.cookies.get(CSRF_COOKIE)?.value;
  const csrfHeader = req.headers.get(CSRF_HEADER);
  if (!csrfCookie || !csrfHeader || !safeEqual(csrfCookie, csrfHeader)) {
    return NextResponse.json({ message: 'Invalid CSRF token' }, { status: 403 });
  }
  return null;
}

async function forward(req: NextRequest, pathParts: string[]) {
  const csrfError = assertCsrf(req);
  if (csrfError) return csrfError;

  const nestPath = `/${pathParts.join('/')}${req.nextUrl.search}`;
  let access = req.cookies.get(ACCESS_COOKIE)?.value ?? null;
  let refresh = req.cookies.get(REFRESH_COOKIE)?.value ?? null;

  if (!access && !refresh) {
    return NextResponse.json({ message: 'Unauthorized' }, { status: 401 });
  }

  const contentType = req.headers.get('content-type') ?? '';
  let body: BodyInit | undefined;
  if (req.method !== 'GET' && req.method !== 'HEAD') {
    if (contentType.includes('multipart/form-data')) {
      body = await req.formData();
    } else {
      const text = await req.text();
      body = text.length ? text : undefined;
    }
  }

  const init: RequestInit = {
    method: req.method,
    body,
  };

  async function call(token: string | null) {
    return nestFetch(nestPath, init, token);
  }

  let upstream = await call(access);
  if (upstream.status === 401 && refresh) {
    try {
      const rotated = await nestRefresh(refresh);
      access = rotated.accessToken;
      refresh = rotated.refreshToken;
      upstream = await call(access);
    } catch {
      const res = NextResponse.json({ message: 'Unauthorized' }, { status: 401 });
      res.cookies.set(ACCESS_COOKIE, '', { ...accessCookieOptions(0), maxAge: 0 });
      res.cookies.set(REFRESH_COOKIE, '', { ...refreshCookieOptions(0), maxAge: 0 });
      return res;
    }
  }

  const buf = await upstream.arrayBuffer();
  const res = new NextResponse(buf, {
    status: upstream.status,
    headers: {
      'Content-Type':
        upstream.headers.get('content-type') ?? 'application/json',
    },
  });
  if (access) res.cookies.set(ACCESS_COOKIE, access, accessCookieOptions());
  if (refresh) res.cookies.set(REFRESH_COOKIE, refresh, refreshCookieOptions());
  return res;
}

export async function GET(req: NextRequest, ctx: Ctx) {
  const { path } = await ctx.params;
  return forward(req, path);
}
export async function POST(req: NextRequest, ctx: Ctx) {
  const { path } = await ctx.params;
  return forward(req, path);
}
export async function PATCH(req: NextRequest, ctx: Ctx) {
  const { path } = await ctx.params;
  return forward(req, path);
}
export async function PUT(req: NextRequest, ctx: Ctx) {
  const { path } = await ctx.params;
  return forward(req, path);
}
export async function DELETE(req: NextRequest, ctx: Ctx) {
  const { path } = await ctx.params;
  return forward(req, path);
}
