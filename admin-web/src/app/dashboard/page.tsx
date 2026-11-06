'use client';

import { useEffect, useState } from 'react';
import { AdminShell } from '@/components/AdminShell';
import { Card, Empty, ErrorText, colors } from '@/components/ui';
import { apiFetch } from '@/lib/api';

type Page<T> = { data: T[]; meta?: { total?: number } };

export default function DashboardPage() {
  const [stats, setStats] = useState({
    orders: 0,
    products: 0,
    users: 0,
    tickets: 0,
  });
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      apiFetch<Page<unknown>>('/admin/orders?limit=1'),
      apiFetch<Page<unknown>>('/admin/products?limit=1'),
      apiFetch<Page<unknown>>('/admin/users?limit=1'),
      apiFetch<Page<unknown>>('/admin/support?limit=1'),
    ])
      .then(([orders, products, users, tickets]) => {
        setStats({
          orders: orders.meta?.total ?? orders.data?.length ?? 0,
          products: products.meta?.total ?? products.data?.length ?? 0,
          users: users.meta?.total ?? users.data?.length ?? 0,
          tickets: tickets.meta?.total ?? tickets.data?.length ?? 0,
        });
      })
      .catch((e) => setError(e instanceof Error ? e.message : 'Ошибка'))
      .finally(() => setLoading(false));
  }, []);

  const tiles = [
    { label: 'Заказы', value: stats.orders },
    { label: 'Товары', value: stats.products },
    { label: 'Пользователи', value: stats.users },
    { label: 'Обращения', value: stats.tickets },
  ];

  return (
    <AdminShell>
      <h1 style={{ marginTop: 0 }}>Обзор магазина</h1>
      {error && <ErrorText>{error}</ErrorText>}
      {loading && <Empty>Загрузка…</Empty>}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
          gap: 12,
          marginTop: 16,
        }}
      >
        {tiles.map((t) => (
          <Card key={t.label}>
            <div style={{ color: colors.muted, fontSize: 13 }}>{t.label}</div>
            <div style={{ fontSize: 28, fontWeight: 800, marginTop: 8 }}>
              {t.value}
            </div>
          </Card>
        ))}
      </div>
    </AdminShell>
  );
}
