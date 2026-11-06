import { CSSProperties, ReactNode } from 'react';

export const colors = {
  bg: '#F7F7F5',
  card: '#FFFFFF',
  text: '#1C2419',
  muted: '#6B7368',
  border: '#E4E4E0',
  orange: '#E8683A',
  danger: '#C94A3A',
  success: '#2F7D4A',
};

export function Card({
  children,
  style,
}: {
  children: ReactNode;
  style?: CSSProperties;
}) {
  return (
    <div
      style={{
        background: colors.card,
        border: `1px solid ${colors.border}`,
        borderRadius: 14,
        padding: 16,
        ...style,
      }}
    >
      {children}
    </div>
  );
}

export function Button({
  children,
  onClick,
  type = 'button',
  variant = 'primary',
  disabled,
  style,
}: {
  children: ReactNode;
  onClick?: () => void;
  type?: 'button' | 'submit';
  variant?: 'primary' | 'ghost' | 'danger';
  disabled?: boolean;
  style?: CSSProperties;
}) {
  const bg =
    variant === 'primary'
      ? colors.orange
      : variant === 'danger'
        ? colors.danger
        : 'transparent';
  const color = variant === 'ghost' ? colors.text : '#fff';
  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled}
      style={{
        background: bg,
        color,
        border:
          variant === 'ghost' ? `1px solid ${colors.border}` : 'none',
        borderRadius: 24,
        padding: '10px 16px',
        fontWeight: 700,
        cursor: disabled ? 'not-allowed' : 'pointer',
        opacity: disabled ? 0.6 : 1,
        ...style,
      }}
    >
      {children}
    </button>
  );
}

export function Input(props: React.InputHTMLAttributes<HTMLInputElement>) {
  return (
    <input
      {...props}
      style={{
        display: 'block',
        width: '100%',
        marginTop: 6,
        padding: 12,
        borderRadius: 12,
        border: `1px solid ${colors.border}`,
        boxSizing: 'border-box',
        ...(props.style ?? {}),
      }}
    />
  );
}

export function TextArea(
  props: React.TextareaHTMLAttributes<HTMLTextAreaElement>,
) {
  return (
    <textarea
      {...props}
      style={{
        display: 'block',
        width: '100%',
        marginTop: 6,
        padding: 12,
        borderRadius: 12,
        border: `1px solid ${colors.border}`,
        boxSizing: 'border-box',
        fontFamily: 'inherit',
        ...(props.style ?? {}),
      }}
    />
  );
}

export function Select(props: React.SelectHTMLAttributes<HTMLSelectElement>) {
  return (
    <select
      {...props}
      style={{
        display: 'block',
        width: '100%',
        marginTop: 6,
        padding: 12,
        borderRadius: 12,
        border: `1px solid ${colors.border}`,
        boxSizing: 'border-box',
        background: '#fff',
        ...(props.style ?? {}),
      }}
    />
  );
}

export function ErrorText({ children }: { children: ReactNode }) {
  return (
    <p style={{ color: colors.danger, whiteSpace: 'pre-wrap' }}>{children}</p>
  );
}

export function Empty({ children }: { children: ReactNode }) {
  return <p style={{ color: colors.muted }}>{children}</p>;
}

export function Table({ children }: { children: ReactNode }) {
  return (
    <div style={{ overflowX: 'auto' }}>
      <table
        style={{
          width: '100%',
          borderCollapse: 'collapse',
          fontSize: 14,
        }}
      >
        {children}
      </table>
    </div>
  );
}

export function Th({ children }: { children?: ReactNode }) {
  return (
    <th
      style={{
        textAlign: 'left',
        padding: '10px 8px',
        borderBottom: `1px solid ${colors.border}`,
        color: colors.muted,
        fontWeight: 600,
      }}
    >
      {children}
    </th>
  );
}

export function Td({ children }: { children?: ReactNode }) {
  return (
    <td
      style={{
        padding: '12px 8px',
        borderBottom: `1px solid ${colors.border}`,
        verticalAlign: 'top',
      }}
    >
      {children}
    </td>
  );
}
