import { backendBaseUrl } from './session';

export type NestLoginResponse = {
  accessToken: string;
  refreshToken: string;
  user: {
    id: string;
    email: string;
    name: string;
    role: string;
  };
};

export async function nestFetch(
  path: string,
  init: RequestInit = {},
  accessToken?: string | null,
): Promise<Response> {
  const p = path.startsWith('/') ? path : `/${path}`;
  const headers = new Headers(init.headers);
  if (accessToken) {
    headers.set('Authorization', `Bearer ${accessToken}`);
  }
  if (
    init.body &&
    !(init.body instanceof FormData) &&
    !headers.has('Content-Type')
  ) {
    headers.set('Content-Type', 'application/json');
  }
  return fetch(`${backendBaseUrl()}/api/v1${p}`, {
    ...init,
    headers,
    cache: 'no-store',
  });
}

export async function nestLogin(
  email: string,
  password: string,
): Promise<NestLoginResponse> {
  const res = await nestFetch('/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(
      (data as { message?: string }).message ?? `Login failed (${res.status})`,
    );
  }
  return data as NestLoginResponse;
}

export async function nestRefresh(
  refreshToken: string,
): Promise<NestLoginResponse> {
  const res = await nestFetch('/auth/refresh', {
    method: 'POST',
    body: JSON.stringify({ refreshToken }),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(
      (data as { message?: string }).message ?? `Refresh failed (${res.status})`,
    );
  }
  return data as NestLoginResponse;
}

export async function nestLogout(refreshToken: string): Promise<void> {
  await nestFetch('/auth/logout', {
    method: 'POST',
    body: JSON.stringify({ refreshToken }),
  });
}
