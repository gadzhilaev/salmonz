'use client';

import { useCallback, useEffect, useState } from 'react';
import { AdminShell } from '@/components/AdminShell';
import {
  Button,
  Card,
  Empty,
  ErrorText,
  Select,
  TextArea,
  colors,
} from '@/components/ui';
import { apiFetch } from '@/lib/api';

type Reply = { id: string; body: string; isStaff: boolean; createdAt: string };
type Ticket = {
  id: string;
  message: string;
  status: string;
  createdAt: string;
  replies?: Reply[];
  user?: { email?: string; name?: string };
};

type Page = { data: Ticket[] };

const STATUSES = ['NEW', 'IN_PROGRESS', 'CLOSED'];

export default function SupportAdminPage() {
  const [tickets, setTickets] = useState<Ticket[]>([]);
  const [active, setActive] = useState<Ticket | null>(null);
  const [reply, setReply] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const loadList = useCallback(async () => {
    const page = await apiFetch<Page>('/admin/support?limit=50');
    setTickets(page.data ?? []);
  }, []);

  async function openTicket(id: string) {
    const t = await apiFetch<Ticket>(`/admin/support/${id}`);
    setActive(t);
  }

  async function sendReply() {
    if (!active || !reply.trim() || busy) return;
    setBusy(true);
    setError(null);
    try {
      const t = await apiFetch<Ticket>(`/admin/support/${active.id}/replies`, {
        method: 'POST',
        body: JSON.stringify({ body: reply.trim() }),
      });
      setActive(t);
      setReply('');
      await loadList();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Ошибка');
    } finally {
      setBusy(false);
    }
  }

  async function setStatus(status: string) {
    if (!active) return;
    setBusy(true);
    try {
      await apiFetch(`/admin/support/${active.id}/status`, {
        method: 'PATCH',
        body: JSON.stringify({ status }),
      });
      await openTicket(active.id);
      await loadList();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Ошибка');
    } finally {
      setBusy(false);
    }
  }

  useEffect(() => {
    loadList().catch((e) =>
      setError(e instanceof Error ? e.message : 'Ошибка'),
    );
  }, [loadList]);

  return (
    <AdminShell>
      <h1 style={{ marginTop: 0 }}>Поддержка</h1>
      {error && <ErrorText>{error}</ErrorText>}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: '320px 1fr',
          gap: 16,
          minHeight: 480,
        }}
      >
        <Card style={{ overflow: 'auto', maxHeight: '70vh' }}>
          {tickets.map((t) => (
            <button
              key={t.id}
              type="button"
              onClick={() => openTicket(t.id)}
              style={{
                display: 'block',
                width: '100%',
                textAlign: 'left',
                border: 'none',
                background: active?.id === t.id ? '#FFE8DF' : 'transparent',
                padding: 10,
                borderRadius: 8,
                cursor: 'pointer',
                marginBottom: 4,
              }}
            >
              <div style={{ fontWeight: 600 }}>
                {t.user?.email ?? t.id.slice(0, 8)}
              </div>
              <div style={{ fontSize: 13, opacity: 0.7 }}>
                {t.status} · {t.message.slice(0, 60)}
              </div>
            </button>
          ))}
          {!tickets.length && <Empty>Обращений пока нет</Empty>}
        </Card>
        <Card
          style={{
            display: 'flex',
            flexDirection: 'column',
            minHeight: 480,
          }}
        >
          {!active && <Empty>Выберите обращение</Empty>}
          {active && (
            <>
              <div
                style={{
                  display: 'flex',
                  gap: 8,
                  alignItems: 'center',
                  marginBottom: 12,
                }}
              >
                <strong style={{ flex: 1 }}>
                  {active.user?.name ?? 'Клиент'} · {active.user?.email}
                </strong>
                <Select
                  value={active.status}
                  disabled={busy}
                  onChange={(e) => setStatus(e.target.value)}
                  style={{ width: 180, marginTop: 0 }}
                >
                  {STATUSES.map((s) => (
                    <option key={s} value={s}>
                      {s}
                    </option>
                  ))}
                </Select>
              </div>
              <div style={{ flex: 1, overflow: 'auto', marginBottom: 12 }}>
                <div
                  style={{
                    padding: 10,
                    borderRadius: 8,
                    background: '#FFE8DF',
                    marginBottom: 10,
                  }}
                >
                  <div style={{ fontSize: 12, color: colors.muted }}>Клиент</div>
                  <div>{active.message}</div>
                </div>
                {(active.replies ?? []).map((r) => (
                  <div
                    key={r.id}
                    style={{
                      marginTop: 10,
                      padding: 10,
                      borderRadius: 8,
                      background: r.isStaff ? '#F0F0ED' : '#FFE8DF',
                    }}
                  >
                    <div style={{ fontSize: 12, opacity: 0.7 }}>
                      {r.isStaff ? 'Оператор' : 'Клиент'} ·{' '}
                      {new Date(r.createdAt).toLocaleString('ru-RU')}
                    </div>
                    <div>{r.body}</div>
                  </div>
                ))}
              </div>
              <TextArea
                value={reply}
                onChange={(e) => setReply(e.target.value)}
                rows={3}
                placeholder="Ответ оператора…"
              />
              <Button
                disabled={busy || !reply.trim()}
                onClick={sendReply}
                style={{ marginTop: 8, alignSelf: 'flex-start' }}
              >
                {busy ? 'Отправка…' : 'Ответить'}
              </Button>
            </>
          )}
        </Card>
      </div>
    </AdminShell>
  );
}
