import { NextResponse } from 'next/server';
import {
  CSRF_COOKIE,
  csrfCookieOptions,
  newCsrfToken,
  readSessionCookies,
} from '@/lib/session';

export async function GET() {
  const { csrf } = await readSessionCookies();
  const token = csrf && csrf.length >= 32 ? csrf : newCsrfToken();
  const res = NextResponse.json({ csrfToken: token });
  if (!csrf || csrf.length < 32) {
    res.cookies.set(CSRF_COOKIE, token, csrfCookieOptions());
  }
  return res;
}
