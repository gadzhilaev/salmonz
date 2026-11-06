'use client';

import { FormEvent, Suspense, useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { ensureCsrf, fetchMe, login } from '@/lib/api';
import { Button, ErrorText, Input, colors } from '@/components/ui';

function LoginForm() {
  const router = useRouter();
  const params = useSearchParams();
  const [email, setEmail] = useState('admin@example.com');
  const [password, setPassword] = useState('ChangeMeAdmin123!');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    ensureCsrf().catch(() => undefined);
    fetchMe().then((me) => {
      if (me.authenticated) {
        router.replace(params.get('next') || '/dashboard');
      }
    });
  }, [router, params]);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      await login(email, password);
      router.replace(params.get('next') || '/dashboard');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка входа');
    } finally {
      setLoading(false);
    }
  }

  return (
    <main style={{ maxWidth: 420, margin: '64px auto', padding: 24 }}>
      <h1 style={{ fontSize: 24, color: colors.text }}>Вход в админку</h1>
      <p style={{ color: colors.muted, marginTop: 8 }}>
        Сессия хранится в HttpOnly cookies. Токены не пишутся в
        localStorage/sessionStorage.
      </p>
      <form
        onSubmit={onSubmit}
        style={{ display: 'grid', gap: 12, marginTop: 24 }}
      >
        <label>
          Email
          <Input
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            type="email"
            required
            autoComplete="username"
          />
        </label>
        <label>
          Пароль
          <Input
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            type="password"
            required
            autoComplete="current-password"
          />
        </label>
        {error && <ErrorText>{error}</ErrorText>}
        <Button type="submit" disabled={loading} style={{ marginTop: 8 }}>
          {loading ? 'Вход…' : 'Войти'}
        </Button>
      </form>
    </main>
  );
}

export default function LoginPage() {
  return (
    <Suspense fallback={<main style={{ padding: 24 }}>Загрузка…</main>}>
      <LoginForm />
    </Suspense>
  );
}
