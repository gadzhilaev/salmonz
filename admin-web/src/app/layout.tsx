import type { Metadata } from 'next';
import type { ReactNode } from 'react';
import './globals.css';

export const metadata: Metadata = {
  title: 'Salmonz Admin',
  description: 'Админ-панель Salmonz',
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="ru">
      <body
        style={{
          margin: 0,
          fontFamily:
            'ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, sans-serif',
          background: '#F7F7F5',
          color: '#1C2419',
        }}
      >
        {children}
      </body>
    </html>
  );
}
