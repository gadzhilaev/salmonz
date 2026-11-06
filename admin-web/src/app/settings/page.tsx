'use client';

import { useEffect, useState } from 'react';
import { AdminShell } from '@/components/AdminShell';
import { Card, Empty, colors } from '@/components/ui';
import { fetchMe } from '@/lib/api';

export default function SettingsPage() {
  const [user, setUser] = useState<{
    email?: string;
    name?: string;
    role?: string;
  } | null>(null);

  useEffect(() => {
    fetchMe().then((me) => {
      if (me.authenticated) setUser(me.user ?? null);
    });
  }, []);

  return (
    <AdminShell>
      <h1 style={{ marginTop: 0 }}>Настройки</h1>
      <Card>
        <h2 style={{ marginTop: 0 }}>Сессия администратора</h2>
        {!user ? (
          <Empty>Загрузка…</Empty>
        ) : (
          <>
            <p>
              <strong>{user.name}</strong> · {user.email}
            </p>
            <p style={{ color: colors.muted }}>Роль: {user.role}</p>
          </>
        )}
        <ul style={{ color: colors.muted, lineHeight: 1.6 }}>
          <li>Access/refresh токены — только HttpOnly cookies (BFF).</li>
          <li>Мутирующие запросы требуют CSRF double-submit.</li>
          <li>Роль ADMIN проверяется на NestJS для всех /admin/*.</li>
          <li>
            Публичные legal-страницы: <code>/legal/privacy</code>,{' '}
            <code>/legal/terms</code> (локальные stubs, не production URL).
          </li>
        </ul>
      </Card>
    </AdminShell>
  );
}
