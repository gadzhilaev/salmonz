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
  Th,
} from '@/components/ui';
import { apiFetch, apiUpload } from '@/lib/api';

type Category = {
  id: string;
  name: string;
  slug: string;
  imageKey?: string | null;
  sortOrder: number;
  isActive: boolean;
};

type Page = { data: Category[] };

const empty = {
  id: '',
  name: '',
  slug: '',
  imageKey: '',
  sortOrder: '0',
  isActive: true,
};

export default function CategoriesPage() {
  const [rows, setRows] = useState<Category[]>([]);
  const [form, setForm] = useState(empty);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    const res = await apiFetch<Page>('/admin/categories?limit=100');
    setRows(res.data ?? []);
  }, []);

  useEffect(() => {
    load().catch((e) => setError(e instanceof Error ? e.message : 'Ошибка'));
  }, [load]);

  function startEdit(c: Category) {
    setForm({
      id: c.id,
      name: c.name,
      slug: c.slug,
      imageKey: c.imageKey ?? '',
      sortOrder: String(c.sortOrder ?? 0),
      isActive: c.isActive,
    });
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    const body = {
      name: form.name.trim(),
      slug: form.slug.trim(),
      imageKey: form.imageKey || null,
      sortOrder: Number(form.sortOrder || 0),
      isActive: form.isActive,
    };
    try {
      if (form.id) {
        await apiFetch(`/admin/categories/${form.id}`, {
          method: 'PATCH',
          body: JSON.stringify(body),
        });
      } else {
        await apiFetch('/admin/categories', {
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
    if (!confirm('Удалить категорию?')) return;
    try {
      await apiFetch(`/admin/categories/${id}`, { method: 'DELETE' });
      if (form.id === id) setForm(empty);
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка');
    }
  }

  return (
    <AdminShell>
      <h1 style={{ marginTop: 0 }}>Категории</h1>
      {error && <ErrorText>{error}</ErrorText>}
      <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr', gap: 16 }}>
        <Card>
          {!rows.length ? (
            <Empty>Категорий нет</Empty>
          ) : (
            <Table>
              <thead>
                <tr>
                  <Th>Название</Th>
                  <Th>Slug</Th>
                  <Th>Порядок</Th>
                  <Th />
                </tr>
              </thead>
              <tbody>
                {rows.map((c) => (
                  <tr key={c.id}>
                    <Td>
                      <button
                        type="button"
                        onClick={() => startEdit(c)}
                        style={{
                          border: 'none',
                          background: 'transparent',
                          fontWeight: 600,
                          cursor: 'pointer',
                          padding: 0,
                        }}
                      >
                        {c.name}
                      </button>
                    </Td>
                    <Td>{c.slug}</Td>
                    <Td>{c.sortOrder}</Td>
                    <Td>
                      <Button variant="danger" onClick={() => onDelete(c.id)}>
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
            {form.id ? 'Редактирование' : 'Новая категория'}
          </h2>
          <form onSubmit={onSubmit} style={{ display: 'grid', gap: 10 }}>
            <label>
              Название
              <Input
                required
                value={form.name}
                onChange={(e) => {
                  const name = e.target.value;
                  setForm((f) => ({
                    ...f,
                    name,
                    slug:
                      f.id || f.slug
                        ? f.slug
                        : name
                            .toLowerCase()
                            .replace(/[^a-zа-я0-9]+/gi, '-')
                            .replace(/^-|-$/g, ''),
                  }));
                }}
              />
            </label>
            <label>
              Slug
              <Input
                required
                value={form.slug}
                onChange={(e) => setForm({ ...form, slug: e.target.value })}
              />
            </label>
            <label>
              Порядок
              <Input
                type="number"
                value={form.sortOrder}
                onChange={(e) => setForm({ ...form, sortOrder: e.target.value })}
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
              Активна
            </label>
            <label>
              Изображение
              <Input
                type="file"
                accept="image/*"
                onChange={(e) => {
                  const file = e.target.files?.[0];
                  if (!file) return;
                  apiUpload<{ key: string }>('/admin/uploads/category', file)
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
