'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { ReactNode, useEffect, useState } from 'react';
import { fetchMe, logout } from '@/lib/api';

const NAV = [
  { href: '/dashboard', label: 'Обзор' },
  { href: '/orders', label: 'Заказы' },
  { href: '/products', label: 'Товары' },
  { href: '/categories', label: 'Категории' },
  { href: '/promotions', label: 'Акции' },
  { href: '/home', label: 'Главная / баннеры' },
  { href: '/users', label: 'Пользователи' },
  { href: '/support', label: 'Поддержка' },
  { href: '/settings', label: 'Настройки' },
];

export function AdminShell({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [email, setEmail] = useState<string | null>(null);

  useEffect(() => {
    fetchMe().then((me) => {
      if (!me.authenticated) {
        router.replace('/login');
        return;
      }
      setEmail(me.user?.email ?? null);
    });
  }, [router]);

  async function onLogout() {
    await logout();
    router.replace('/login');
  }

  return (
    <div
      style={{
        display: 'grid',
        gridTemplateColumns: '240px 1fr',
        minHeight: '100vh',
      }}
    >
      <aside
        style={{
          background: '#1C2419',
          color: '#fff',
          padding: '20px 14px',
          display: 'flex',
          flexDirection: 'column',
          gap: 8,
        }}
      >
        <div style={{ fontWeight: 800, fontSize: 18, marginBottom: 12 }}>
          Salmonz Admin
        </div>
        {NAV.map((item) => {
          const active =
            pathname === item.href || pathname.startsWith(`${item.href}/`);
          return (
            <Link
              key={item.href}
              href={item.href}
              style={{
                padding: '10px 12px',
                borderRadius: 10,
                textDecoration: 'none',
                color: '#fff',
                background: active ? '#E8683A' : 'transparent',
                fontWeight: active ? 700 : 500,
                fontSize: 14,
              }}
            >
              {item.label}
            </Link>
          );
        })}
        <div style={{ flex: 1 }} />
        <div style={{ fontSize: 12, opacity: 0.7, marginBottom: 8 }}>
          {email}
        </div>
        <button
          type="button"
          onClick={onLogout}
          style={{
            background: 'transparent',
            border: '1px solid rgba(255,255,255,0.25)',
            color: '#fff',
            borderRadius: 10,
            padding: '10px 12px',
            cursor: 'pointer',
            textAlign: 'left',
          }}
        >
          Выйти
        </button>
      </aside>
      <main style={{ padding: 24, maxWidth: 1200 }}>{children}</main>
      <style>{`
        @media (max-width: 860px) {
          div[style*="grid-template-columns: 240px"] {
            grid-template-columns: 1fr !important;
          }
          aside {
            position: sticky;
            top: 0;
            z-index: 10;
            flex-direction: row !important;
            flex-wrap: wrap;
            align-items: center;
          }
        }
      `}</style>
    </div>
  );
}
