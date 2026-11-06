'use client';

import { FormEvent, useCallback, useEffect, useState } from 'react';
import { AdminShell } from '@/components/AdminShell';
import {
  Button,
  Card,
  Empty,
  ErrorText,
  Input,
  Table,
  Td,
  TextArea,
  Th,
} from '@/components/ui';
import { apiFetch, apiUpload } from '@/lib/api';

type Promo = {
  id: string;
  title: string;
  description?: string | null;
  imageKey: string;
  isActive: boolean;
  sortOrder: number;
  startsAt?: string | null;
  endsAt?: string | null;
};

type Page = { data: Promo[] };

const empty = {
  id: '',
  title: '',
  description: '',
  imageKey: '',
  isActive: true,
  sortOrder: '0',
  startsAt: '',
  endsAt: '',
};

export default function PromotionsPage() {
  const [rows, setRows] = useState<Promo[]>([]);
  const [form, setForm] = useState(empty);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    const res = await apiFetch<Page>('/admin/promotions?limit=100');
    setRows(res.data ?? []);
  }, []);

  useEffect(() => {
    load().catch((e) => setError(e instanceof Error ? e.message : 'Ошибка'));
  }, [load]);

  function startEdit(p: Promo) {
    setForm({
      id: p.id,
      title: p.title,
      description: p.description ?? '',
      imageKey: p.imageKey,
      isActive: p.isActive,
      sortOrder: String(p.sortOrder ?? 0),
      startsAt: p.startsAt ? p.startsAt.slice(0, 16) : '',
      endsAt: p.endsAt ? p.endsAt.slice(0, 16) : '',
    });
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (!form.imageKey) {
      setError('Нужно загрузить изображение');
      return;
    }
    setBusy(true);
    setError(null);
    const body = {
      title: form.title.trim(),
      description: form.description.trim() || null,
      imageKey: form.imageKey,
      isActive: form.isActive,
      sortOrder: Number(form.sortOrder || 0),
      startsAt: form.startsAt ? new Date(form.startsAt).toISOString() : null,
      endsAt: form.endsAt ? new Date(form.endsAt).toISOString() : null,
    };
    try {
      if (form.id) {
        await apiFetch(`/admin/promotions/${form.id}`, {
          method: 'PATCH',
          body: JSON.stringify(body),
        });
      } else {
        await apiFetch('/admin/promotions', {
          method: 'POST',
          body: JSON.stringify(body),
        });
      }
      setForm(empty);
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка');
    } finally {
      setBusy(false);
    }
  }

  async function onDelete(id: string) {
    if (!confirm('Удалить акцию?')) return;
    try {
      await apiFetch(`/admin/promotions/${id}`, { method: 'DELETE' });
      if (form.id === id) setForm(empty);
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка');
    }
  }

  return (
    <AdminShell>
      <h1 style={{ marginTop: 0 }}>Акции</h1>
      {error && <ErrorText>{error}</ErrorText>}
      <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr', gap: 16 }}>
        <Card>
          {!rows.length ? (
            <Empty>Акций нет</Empty>
          ) : (
            <Table>
              <thead>
                <tr>
                  <Th>Заголовок</Th>
                  <Th>Активна</Th>
                  <Th>Порядок</Th>
                  <Th />
                </tr>
              </thead>
              <tbody>
                {rows.map((p) => (
                  <tr key={p.id}>
                    <Td>
                      <button
                        type="button"
                        onClick={() => startEdit(p)}
                        style={{
                          border: 'none',
                          background: 'transparent',
                          fontWeight: 600,
                          cursor: 'pointer',
                          padding: 0,
                        }}
                      >
                        {p.title}
                      </button>
                    </Td>
                    <Td>{p.isActive ? 'да' : 'нет'}</Td>
                    <Td>{p.sortOrder}</Td>
                    <Td>
                      <Button variant="danger" onClick={() => onDelete(p.id)}>
                        Удалить
                      </Button>
                    </Td>
                  </tr>
                ))}
              </tbody>
            </Table>
          )}
        </Card>
        <Card>
          <h2 style={{ marginTop: 0 }}>
            {form.id ? 'Редактирование' : 'Новая акция'}
          </h2>
          <form onSubmit={onSubmit} style={{ display: 'grid', gap: 10 }}>
            <label>
              Заголовок
              <Input
                required
                value={form.title}
                onChange={(e) => setForm({ ...form, title: e.target.value })}
              />
            </label>
            <label>
              Описание
              <TextArea
                rows={3}
                value={form.description}
                onChange={(e) =>
                  setForm({ ...form, description: e.target.value })
                }
              />
            </label>
            <label>
              Порядок (влияет на главную)
              <Input
                type="number"
                value={form.sortOrder}
                onChange={(e) => setForm({ ...form, sortOrder: e.target.value })}
              />
            </label>
            <label>
              Начало
              <Input
                type="datetime-local"
                value={form.startsAt}
                onChange={(e) => setForm({ ...form, startsAt: e.target.value })}
              />
            </label>
            <label>
              Конец
              <Input
                type="datetime-local"
                value={form.endsAt}
                onChange={(e) => setForm({ ...form, endsAt: e.target.value })}
              />
            </label>
            <label style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
              <input
                type="checkbox"
                checked={form.isActive}
                onChange={(e) =>
                  setForm({ ...form, isActive: e.target.checked })
                }
              />
              Активна / видима на главной
            </label>
            <label>
              Изображение баннера
              <Input
                type="file"
                accept="image/*"
                onChange={(e) => {
                  const file = e.target.files?.[0];
                  if (!file) return;
                  apiUpload<{ key: string }>('/admin/uploads/promotion', file)
                    .then((up) => setForm((f) => ({ ...f, imageKey: up.key })))
                    .catch((err) =>
                      setError(err instanceof Error ? err.message : 'Upload'),
                    );
                }}
              />
              {form.imageKey && <small>key: {form.imageKey}</small>}
            </label>
            <Button type="submit" disabled={busy}>
              {busy ? 'Сохранение…' : form.id ? 'Сохранить' : 'Создать'}
            </Button>
          </form>
        </Card>
      </div>
    </AdminShell>
  );
}
