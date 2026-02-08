import React from 'react';
import { NavLink } from 'react-router-dom';

const navItems = [
  { to: '/home', label: 'Home' },
  { to: '/petdiary', label: 'Diary' },
  { to: '/pictures', label: 'Pictures' },
  { to: '/chat', label: 'Chat' },
  { to: '/settings', label: 'Settings' },
];

function BottomNav() {
  return (
    <nav
      style={{
        position: 'fixed',
        left: 0,
        right: 0,
        bottom: 0,
        zIndex: 2000,
        borderTop: '1px solid var(--border)',
        background: 'var(--surface-strong)',
        backdropFilter: 'blur(8px)',
        padding: '10px 10px calc(10px + env(safe-area-inset-bottom))',
      }}
    >
      <div
        style={{
          maxWidth: '1080px',
          margin: '0 auto',
          display: 'grid',
          gridTemplateColumns: 'repeat(5, minmax(0, 1fr))',
          gap: '8px',
        }}
      >
        {navItems.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            style={({ isActive }) => ({
              textAlign: 'center',
              textDecoration: 'none',
              borderRadius: '10px',
              padding: '10px 8px',
              fontWeight: 700,
              fontSize: '0.9em',
              border: '1px solid var(--border)',
              color: isActive ? 'white' : 'var(--text)',
              background: isActive ? 'var(--accent)' : 'transparent',
            })}
          >
            {item.label}
          </NavLink>
        ))}
      </div>
    </nav>
  );
}

export default BottomNav;
