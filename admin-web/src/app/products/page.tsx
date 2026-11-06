'use client';

import { FormEvent, useCallback, useEffect, useState } from 'react';
import { AdminShell } from '@/components/AdminShell';
import {
  Button,
  Card,
  Empty,
  ErrorText,
  Input,
  Select,
  Table,
  Td,
  TextArea,
  Th,
} from '@/components/ui';
import { apiFetch, apiUpload } from '@/lib/api';

type Category = { id: string; name: string };
type Product = {
  id: string;
  name: string;
  description?: string;
  price: number | string;
  oldPrice?: number | string | null;
  categoryId: string;
  imageKey?: string | null;
  imageUrl?: string | null;
  weight?: number | null;
  isAvailable: boolean;
  sortOrder?: number;
};

type Page<T> = { data: T[] };

const emptyForm = {
  id: '',
  name: '',
  description: '',
  price: '',
  oldPrice: '',
  categoryId: '',
  weight: '',
  imageKey: '',
  isAvailable: true,
  sortOrder: '0',
};

export default function ProductsPage() {
  const [rows, setRows] = useState<Product[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [q, setQ] = useState('');
  const [form, setForm] = useState(emptyForm);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const editing = Boolean(form.id);

  const load = useCallback(async () => {
    const [products, cats] = await Promise.all([
      apiFetch<Page<Product>>('/admin/products?limit=100'),
      apiFetch<Page<Category>>('/admin/categories?limit=100'),
    ]);
    setRows(products.data ?? []);
    setCategories(cats.data ?? []);
    if (!form.categoryId && cats.data?.[0]) {
      setForm((f) => ({ ...f, categoryId: cats.data[0].id }));
    }
  }, [form.categoryId]);

  useEffect(() => {
    load().catch((e) => setError(e instanceof Error ? e.message : 'Ошибка'));
  }, [load]);

  function startEdit(p: Product) {
    setForm({
      id: p.id,
      name: p.name,
      description: p.description ?? '',
      price: String(p.price),
      oldPrice: p.oldPrice != null ? String(p.oldPrice) : '',
      categoryId: p.categoryId,
      weight: p.weight != null ? String(p.weight) : '',
      imageKey: p.imageKey ?? '',
      isAvailable: p.isAvailable,
      sortOrder: String(p.sortOrder ?? 0),
    });
  }

  async function onUpload(file: File) {
    const up = await apiUpload<{ key: string }>('/admin/uploads/product', file);
    setForm((f) => ({ ...f, imageKey: up.key }));
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    const body = {
      name: form.name.trim(),
      description: form.description.trim(),
      price: Number(form.price),
      oldPrice: form.oldPrice ? Number(form.oldPrice) : null,
      categoryId: form.categoryId,
      weight: form.weight ? Number(form.weight) : null,
      imageKey: form.imageKey || null,
      isAvailable: form.isAvailable,
      sortOrder: Number(form.sortOrder || 0),
    };
    try {
      if (editing) {
        await apiFetch(`/admin/products/${form.id}`, {
          method: 'PATCH',
          body: JSON.stringify(body),
        });
      } else {
        await apiFetch('/admin/products', {
          method: 'POST',
          body: JSON.stringify(body),
        });
      }
      setForm({ ...emptyForm, categoryId: form.categoryId });
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка');
    } finally {
      setBusy(false);
    }
  }

  async function onDelete(id: string) {
    if (!confirm('Удалить товар?')) return;
    setBusy(true);
    try {
      await apiFetch(`/admin/products/${id}`, { method: 'DELETE' });
      if (form.id === id) setForm({ ...emptyForm, categoryId: form.categoryId });
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка');
    } finally {
      setBusy(false);
    }
  }

  const filtered = rows.filter((r) =>
    r.name.toLowerCase().includes(q.trim().toLowerCase()),
  );

  return (
    <AdminShell>
      <h1 style={{ marginTop: 0 }}>Товары</h1>
      {error && <ErrorText>{error}</ErrorText>}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: '1.3fr 1fr',
          gap: 16,
        }}
      >
        <Card>
          <Input
            placeholder="Поиск…"
            value={q}
            onChange={(e) => setQ(e.target.value)}
            style={{ marginBottom: 12 }}
          />
          {!filtered.length ? (
            <Empty>Товаров нет</Empty>
          ) : (
            <Table>
              <thead>
                <tr>
                  <Th>Название</Th>
                  <Th>Цена</Th>
                  <Th>Доступен</Th>
                  <Th />
                </tr>
              </thead>
              <tbody>
                {filtered.map((p) => (
                  <tr key={p.id}>
                    <Td>
                      <button
                        type="button"
                        onClick={() => startEdit(p)}
                        style={{
                          border: 'none',
                          background: 'transparent',
                          padding: 0,
                          cursor: 'pointer',
                          fontWeight: 600,
                          textAlign: 'left',
                        }}
                      >
                        {p.name}
                      </button>
                    </Td>
                    <Td>{Number(p.price).toLocaleString('ru-RU')} ₽</Td>
                    <Td>{p.isAvailable ? 'да' : 'нет'}</Td>
                    <Td>
                      <Button
                        variant="danger"
                        disabled={busy}
                        onClick={() => onDelete(p.id)}
                      >
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
            {editing ? 'Редактирование' : 'Новый товар'}
          </h2>
          <form onSubmit={onSubmit} style={{ display: 'grid', gap: 10 }}>
            <label>
              Название
              <Input
                required
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
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
              Категория
              <Select
                required
                value={form.categoryId}
                onChange={(e) =>
                  setForm({ ...form, categoryId: e.target.value })
                }
              >
                {categories.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
              </Select>
            </label>
            <label>
              Цена
              <Input
                required
                type="number"
                min={0}
                step="0.01"
                value={form.price}
                onChange={(e) => setForm({ ...form, price: e.target.value })}
              />
            </label>
            <label>
              Старая цена
              <Input
                type="number"
                min={0}
                step="0.01"
                value={form.oldPrice}
                onChange={(e) => setForm({ ...form, oldPrice: e.target.value })}
              />
            </label>
            <label>
              Вес (г)
              <Input
                type="number"
                min={0}
                value={form.weight}
                onChange={(e) => setForm({ ...form, weight: e.target.value })}
              />
            </label>
            <label>
              Порядок
              <Input
                type="number"
                value={form.sortOrder}
                onChange={(e) =>
                  setForm({ ...form, sortOrder: e.target.value })
                }
              />
            </label>
            <label style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
              <input
                type="checkbox"
                checked={form.isAvailable}
                onChange={(e) =>
                  setForm({ ...form, isAvailable: e.target.checked })
                }
              />
              Доступен
            </label>
            <label>
              Изображение
              <Input
                type="file"
                accept="image/*"
                onChange={(e) => {
                  const file = e.target.files?.[0];
                  if (file) {
                    onUpload(file).catch((err) =>
                      setError(err instanceof Error ? err.message : 'Upload'),
                    );
                  }
                }}
              />
              {form.imageKey && (
                <small style={{ display: 'block', marginTop: 6 }}>
                  key: {form.imageKey}
                </small>
              )}
            </label>
            <div style={{ display: 'flex', gap: 8 }}>
              <Button type="submit" disabled={busy}>
                {busy ? 'Сохранение…' : editing ? 'Сохранить' : 'Создать'}
              </Button>
              {editing && (
                <Button
                  variant="ghost"
                  onClick={() =>
                    setForm({ ...emptyForm, categoryId: form.categoryId })
                  }
                >
                  Сброс
                </Button>
              )}
            </div>
          </form>
        </Card>
      </div>
    </AdminShell>
  );
}
