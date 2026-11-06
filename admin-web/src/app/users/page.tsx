'use client';

import { useCallback, useEffect, useState } from 'react';
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
  colors,
} from '@/components/ui';
import { apiFetch } from '@/lib/api';

type User = {
  id: string;
  email: string;
  name: string;
  phone?: string | null;
  role: string;
  isActive?: boolean;
  createdAt: string;
};

type Page = {
  data: User[];
  meta?: { page: number; totalPages: number; total: number };
};

export default function UsersPage() {
  const [rows, setRows] = useState<User[]>([]);
  const [q, setQ] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const [meta, setMeta] = useState<Page['meta']>();

  const load = useCallback(async () => {
    const res = await apiFetch<Page>(`/admin/users?page=${page}&limit=50`);
    setRows(res.data ?? []);
    setMeta(res.meta);
  }, [page]);

  useEffect(() => {
    load().catch((e) => setError(e instanceof Error ? e.message : 'Ошибка'));
  }, [load]);

  const filtered = rows.filter((u) => {
    const s = q.trim().toLowerCase();
    if (!s) return true;
    return (
      u.email.toLowerCase().includes(s) ||
      u.name.toLowerCase().includes(s) ||
      (u.phone ?? '').includes(s)
    );
  });

  return (
    <AdminShell>
      <h1 style={{ marginTop: 0 }}>Пользователи</h1>
      {error && <ErrorText>{error}</ErrorText>}
      <Card>
        <Input
          placeholder="Поиск по email / имени / телефону"
          value={q}
          onChange={(e) => setQ(e.target.value)}
          style={{ marginBottom: 12 }}
        />
        {!filtered.length ? (
          <Empty>Пользователей нет</Empty>
        ) : (
          <Table>
            <thead>
              <tr>
                <Th>Имя</Th>
                <Th>Email</Th>
                <Th>Телефон</Th>
                <Th>Роль</Th>
                <Th>Создан</Th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((u) => (
                <tr key={u.id}>
                  <Td>{u.name}</Td>
                  <Td>{u.email}</Td>
                  <Td>{u.phone ?? '—'}</Td>
                  <Td>{u.role}</Td>
                  <Td>{new Date(u.createdAt).toLocaleString('ru-RU')}</Td>
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
    </AdminShell>
  );
}
