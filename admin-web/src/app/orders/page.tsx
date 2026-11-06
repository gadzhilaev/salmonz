'use client';

import { useCallback, useEffect, useState } from 'react';
import { AdminShell } from '@/components/AdminShell';
import {
  Button,
  Card,
  Empty,
  ErrorText,
  Select,
  Table,
  Td,
  Th,
  colors,
} from '@/components/ui';
import { apiFetch } from '@/lib/api';

type Order = {
  id: string;
  publicNumber: string;
  status: string;
  total: number;
  phone: string;
  createdAt: string;
  user?: { email?: string; name?: string };
  items?: Array<{ productNameSnapshot: string; quantity: number }>;
};

type Page = { data: Order[]; meta?: { page: number; totalPages: number; total: number } };

const STATUSES = [
  'NEW',
  'CONFIRMED',
  'PREPARING',
  'READY',
  'DELIVERING',
  'COMPLETED',
  'CANCELLED',
];

export default function OrdersPage() {
  const [rows, setRows] = useState<Order[]>([]);
  const [selected, setSelected] = useState<Order | null>(null);
  const [statusFilter, setStatusFilter] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [page, setPage] = useState(1);
  const [meta, setMeta] = useState<Page['meta']>();

  const load = useCallback(async () => {
    const q = new URLSearchParams({ page: String(page), limit: '20' });
    if (statusFilter) q.set('status', statusFilter);
    const res = await apiFetch<Page>(`/admin/orders?${q}`);
    setRows(res.data ?? []);
    setMeta(res.meta);
  }, [page, statusFilter]);

  useEffect(() => {
    load().catch((e) => setError(e instanceof Error ? e.message : 'Ошибка'));
  }, [load]);

  async function openOrder(id: string) {
    const order = await apiFetch<Order>(`/admin/orders/${id}`);
    setSelected(order);
  }

  async function changeStatus(status: string) {
    if (!selected || busy) return;
    if (!confirm(`Сменить статус на ${status}?`)) return;
    setBusy(true);
    setError(null);
    try {
      const updated = await apiFetch<Order>(
        `/admin/orders/${selected.id}/status`,
        {
          method: 'PATCH',
          body: JSON.stringify({ status }),
        },
      );
      setSelected(updated);
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Ошибка');
    } finally {
      setBusy(false);
    }
  }

  return (
    <AdminShell>
      <h1 style={{ marginTop: 0 }}>Заказы</h1>
      <div style={{ display: 'flex', gap: 12, marginBottom: 16, flexWrap: 'wrap' }}>
        <label style={{ minWidth: 200 }}>
          Статус
          <Select
            value={statusFilter}
            onChange={(e) => {
              setPage(1);
              setStatusFilter(e.target.value);
            }}
          >
            <option value="">Все</option>
            {STATUSES.map((s) => (
              <option key={s} value={s}>
                {s}
              </option>
            ))}
          </Select>
        </label>
      </div>
      {error && <ErrorText>{error}</ErrorText>}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: selected ? '1.2fr 1fr' : '1fr',
          gap: 16,
        }}
      >
        <Card>
          {!rows.length ? (
            <Empty>Заказов нет</Empty>
          ) : (
            <Table>
              <thead>
                <tr>
                  <Th>Номер</Th>
                  <Th>Клиент</Th>
                  <Th>Статус</Th>
                  <Th>Сумма</Th>
                </tr>
              </thead>
              <tbody>
                {rows.map((o) => (
                  <tr
                    key={o.id}
                    onClick={() => openOrder(o.id)}
                    style={{ cursor: 'pointer' }}
                  >
                    <Td>
                      <strong>{o.publicNumber}</strong>
                    </Td>
                    <Td>{o.user?.email ?? o.phone}</Td>
                    <Td>{o.status}</Td>
                    <Td>{Number(o.total).toLocaleString('ru-RU')} ₽</Td>
                  </tr>
                ))}
              </tbody>
            </Table>
          )}
          <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
            <Button
              variant="ghost"
              disabled={page <= 1}
              onClick={() => setPage((p) => Math.max(1, p - 1))}
            >
              Назад
            </Button>
            <span style={{ color: colors.muted, alignSelf: 'center' }}>
              стр. {meta?.page ?? page}
              {meta?.totalPages ? ` / ${meta.totalPages}` : ''}
            </span>
            <Button
              variant="ghost"
              disabled={Boolean(meta?.totalPages && page >= meta.totalPages)}
              onClick={() => setPage((p) => p + 1)}
            >
              Вперёд
            </Button>
          </div>
        </Card>
        {selected && (
          <Card>
            <h2 style={{ marginTop: 0 }}>{selected.publicNumber}</h2>
            <p style={{ color: colors.muted }}>
              {selected.user?.name} · {selected.user?.email}
            </p>
            <p>Телефон: {selected.phone}</p>
            <p>
              Сумма: <strong>{Number(selected.total).toLocaleString('ru-RU')} ₽</strong>
            </p>
            <p>Статус: {selected.status}</p>
            <ul>
              {(selected.items ?? []).map((i, idx) => (
                <li key={idx}>
                  {i.productNameSnapshot} × {i.quantity}
                </li>
              ))}
            </ul>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
              {STATUSES.map((s) => (
                <Button
                  key={s}
                  variant={s === 'CANCELLED' ? 'danger' : 'ghost'}
                  disabled={busy || s === selected.status}
                  onClick={() => changeStatus(s)}
                >
                  {s}
                </Button>
              ))}
            </div>
          </Card>
        )}
      </div>
    </AdminShell>
  );
}
