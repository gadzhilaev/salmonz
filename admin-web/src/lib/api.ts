/**
 * Browser client for admin-web.
 * Tokens live only in HttpOnly cookies set by Next BFF routes.
 * Never use localStorage/sessionStorage for auth tokens.
 */

import { CSRF_COOKIE, CSRF_HEADER } from './auth-constants';

let csrfMemory: string | null = null;

function readCsrfFromDocument(): string | null {
  if (typeof document === 'undefined') return null;
  const match = document.cookie
    .split(';')
    .map((c) => c.trim())
    .find((c) => c.startsWith(`${CSRF_COOKIE}=`));
  if (!match) return null;
  return decodeURIComponent(match.slice(CSRF_COOKIE.length + 1));
}

export async function ensureCsrf(): Promise<string> {
  const existing = csrfMemory ?? readCsrfFromDocument();
  if (existing && existing.length >= 32) {
    csrfMemory = existing;
    return existing;
  }
  const res = await fetch('/api/auth/csrf', { credentials: 'same-origin' });
  const data = (await res.json()) as { csrfToken: string };
  csrfMemory = data.csrfToken;
  return data.csrfToken;
}

export async function apiFetch<T>(
  path: string,
  init: RequestInit = {},
): Promise<T> {
  const csrf = await ensureCsrf();
  const p = path.startsWith('/') ? path : `/${path}`;
  const headers = new Headers(init.headers);
  headers.set(CSRF_HEADER, csrf);
  const isForm = typeof FormData !== 'undefined' && init.body instanceof FormData;
  if (init.body && !isForm && !headers.has('Content-Type')) {
    headers.set('Content-Type', 'application/json');
  }

  const res = await fetch(`/api/proxy${p}`, {
    ...init,
    headers,
    credentials: 'same-origin',
  });

  if (res.status === 401) {
    if (typeof window !== 'undefined' && !window.location.pathname.startsWith('/login')) {
      window.location.href = '/login';
    }
    throw new Error('Unauthorized');
  }

  if (!res.ok) {
    const text = await res.text();
    let message = text || `HTTP ${res.status}`;
    try {
      const json = JSON.parse(text) as { message?: string | string[] };
      if (typeof json.message === 'string') message = json.message;
      else if (Array.isArray(json.message)) message = json.message.join(', ');
    } catch {
      // keep raw
    }
    throw new Error(message);
  }

  if (res.status === 204) return undefined as T;
  const ct = res.headers.get('content-type') ?? '';
  if (ct.includes('application/json')) {
    return (await res.json()) as T;
  }
  return (await res.text()) as T;
}

export async function apiUpload<T>(
  path: string,
  file: File,
  fieldName = 'file',
): Promise<T> {
  const form = new FormData();
  form.append(fieldName, file);
  return apiFetch<T>(path, { method: 'POST', body: form });
}

export async function login(email: string, password: string) {
  const csrf = await ensureCsrf();
  const res = await fetch('/api/auth/login', {
    method: 'POST',
    credentials: 'same-origin',
    headers: {
      'Content-Type': 'application/json',
      [CSRF_HEADER]: csrf,
    },
    body: JSON.stringify({ email, password }),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(
      (data as { message?: string }).message ?? `Login failed (${res.status})`,
    );
  }
  // Login rotates CSRF cookie — refresh memory from Set-Cookie via ensureCsrf next call
  csrfMemory = null;
  await ensureCsrf();
  return data as { user: { id: string; email: string; name: string; role: string } };
}

export async function logout() {
  const csrf = await ensureCsrf();
  await fetch('/api/auth/logout', {
    method: 'POST',
    credentials: 'same-origin',
    headers: { [CSRF_HEADER]: csrf },
  });
  csrfMemory = null;
}

export async function fetchMe(): Promise<{
  authenticated: boolean;
  user?: { id: string; email: string; name: string; role: string };
}> {
  const res = await fetch('/api/auth/me', { credentials: 'same-origin' });
  if (!res.ok) return { authenticated: false };
  return (await res.json()) as {
    authenticated: boolean;
    user?: { id: string; email: string; name: string; role: string };
  };
}

/** @deprecated tokens are never stored in the browser */
export function loadTokens(): null {
  return null;
}

/** @deprecated no-op — cookies are managed by BFF */
export function saveTokens(_: unknown): void {
  void _;
}
