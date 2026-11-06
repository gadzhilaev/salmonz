'use client';

import { useCallback, useEffect, useState } from 'react';
import { AdminShell } from '@/components/AdminShell';
import {
  Button,
  Card,
  Empty,
  ErrorText,
  Input,
  colors,
} from '@/components/ui';
import { apiFetch } from '@/lib/api';

type Promo = {
  id: string;
  title: string;
  isActive: boolean;
  sortOrder: number;
  imageKey: string;
};

type Page = { data: Promo[] };

/**
 * Home / banners are driven by promotions (sortOrder + isActive).
 * There is no separate Banner model in the current Nest schema.
 */
export default function HomePage() {
  const [rows, setRows] = useState<Promo[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);

  const load = useCallback(async () => {
    const res = await apiFetch<Page>('/admin/promotions?limit=100');
    const sorted = [...(res.data ?? [])].sort(
      (a, b) => a.sortOrder - b.sortOrder,
    );
    setRows(sorted);
  }, []);

  useEffect(() => {
    load().catch((e) => setError(e instanceof Error ? e.message : 'Ошибка'));
  }, [load]);

  async function patch(id: string, body: Partial<Promo>) {
    setBusyId(id);
    setError(null);
    try {
      await apiFetch(`/admin/promotions/${id}`, {
        method: 'PATCH',
        body: JSON.stringify(body),
      });
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Ошибка');
    } finally {
      setBusyId(null);
    }
  }

  async function move(id: string, dir: -1 | 1) {
    const idx = rows.findIndex((r) => r.id === id);
    const swap = rows[idx + dir];
    if (!swap) return;
    const a = rows[idx];
    await Promise.all([
      patch(a.id, { sortOrder: swap.sortOrder }),
      patch(swap.id, { sortOrder: a.sortOrder }),
    ]);
  }

  return (
    <AdminShell>
      <h1 style={{ marginTop: 0 }}>Главная / баннеры</h1>
      <p style={{ color: colors.muted }}>
        Порядок и видимость блоков главной управляются через акции
        (promotions). Изменения сразу видны в Flutter после обновления каталога.
      </p>
      {error && <ErrorText>{error}</ErrorText>}
      {!rows.length ? (
        <Empty>Нет баннеров. Создайте акцию в разделе «Акции».</Empty>
      ) : (
        <div style={{ display: 'grid', gap: 12 }}>
          {rows.map((p, index) => (
            <Card
              key={p.id}
              style={{
                display: 'flex',
                gap: 12,
                alignItems: 'center',
                opacity: p.isActive ? 1 : 0.55,
              }}
            >
              <div style={{ flex: 1 }}>
                <strong>{p.title}</strong>
                <div style={{ color: colors.muted, fontSize: 13 }}>
                  sortOrder: {p.sortOrder} · {p.imageKey}
                </div>
              </div>
              <label style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                <input
                  type="checkbox"
                  checked={p.isActive}
                  disabled={busyId === p.id}
                  onChange={(e) => patch(p.id, { isActive: e.target.checked })}
                />
                На главной
              </label>
              <Input
                type="number"
                style={{ width: 90 }}
                defaultValue={p.sortOrder}
                onBlur={(e) => {
                  const v = Number(e.target.value);
                  if (!Number.isNaN(v) && v !== p.sortOrder) {
                    patch(p.id, { sortOrder: v });
                  }
                }}
              />
              <Button
                variant="ghost"
                disabled={index === 0 || busyId === p.id}
                onClick={() => move(p.id, -1)}
              >
                ↑
              </Button>
              <Button
                variant="ghost"
                disabled={index === rows.length - 1 || busyId === p.id}
                onClick={() => move(p.id, 1)}
              >
                ↓
              </Button>
            </Card>
          ))}
        </div>
      )}
    </AdminShell>
  );
}
