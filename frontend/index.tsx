import React from 'react';
import { createRoot } from 'react-dom/client';

const DesignTokens = {
  colors: {
    background: 'linear-gradient(135deg, #FDFCF0 0%, #E2F2D5 100%)',
    surface: '#FFFFFF',
    primary: '#97B476',
    secondary: '#B199F9',
    textPrimary: '#1D2939',
    textSecondary: '#667085',
    border: '#F2F4F7',
  },
  radius: {
    m: '16px',
    circle: '500px',
  }
};

const App = () => {
  return (
    <div style={{ 
      background: DesignTokens.colors.background, 
      minHeight: '100vh', 
      fontFamily: 'system-ui, -apple-system, sans-serif',
      padding: '40px 20px',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center'
    }}>
      <div style={{ width: '100%', maxWidth: '390px' }}>
        
        {/* iOS Status Bar Placeholder */}
        <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0 20px 20px' }}>
          <span style={{ fontWeight: 'bold' }}>9:41</span>
          <div style={{ display: 'flex', gap: '5px' }}>
            <div style={{ width: '16px', height: '10px', background: '#000', borderRadius: '2px' }}></div>
          </div>
        </div>

        {/* Header Preview */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '32px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div style={{ width: '48px', height: '48px', background: DesignTokens.colors.primary, borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
               <span style={{ fontSize: '24px' }}>🐾</span>
            </div>
            <div>
              <h1 style={{ margin: 0, fontSize: '20px', fontWeight: 'bold', color: DesignTokens.colors.textPrimary }}>Pixel</h1>
              <span style={{ 
                background: DesignTokens.colors.secondary, 
                color: 'white', 
                fontSize: '12px', 
                padding: '2px 8px', 
                borderRadius: '12px',
                fontWeight: 'bold'
              }}>LVL 12</span>
            </div>
          </div>
          <button style={{ 
            width: '44px', height: '44px', 
            borderRadius: '50%', background: 'white', 
            border: `1px solid ${DesignTokens.colors.border}`,
            boxShadow: '0 4px 12px rgba(0,0,0,0.06)',
            fontSize: '20px', cursor: 'pointer'
          }}>🔔</button>
        </div>

        {/* Card Preview */}
        <div style={{ 
          background: 'white', 
          padding: '20px', 
          borderRadius: DesignTokens.radius.m,
          border: `1px solid ${DesignTokens.colors.border}`,
          boxShadow: '0 8px 24px rgba(0,0,0,0.08)',
          marginBottom: '24px'
        }}>
          <h2 style={{ margin: '0 0 8px 0', fontSize: '18px', fontWeight: 'bold' }}>Daily Quest</h2>
          <p style={{ margin: 0, color: DesignTokens.colors.textSecondary, lineHeight: '1.4' }}>
            Take Pixel for a 15-minute walk to earn 50 XP.
          </p>
        </div>

        {/* Grid Preview */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '16px' }}>
          {['Diary', 'Gallery', 'Chat', 'Health'].map((item, idx) => (
            <div key={item} style={{ 
              background: 'white', 
              aspectRatio: '1', 
              borderRadius: DesignTokens.radius.m,
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '8px',
              border: `1px solid ${DesignTokens.colors.border}`,
              boxShadow: '0 4px 12px rgba(0,0,0,0.04)'
            }}>
              <span style={{ fontSize: '32px' }}>{['📖', '🖼️', '💬', '❤️'][idx]}</span>
              <span style={{ fontWeight: 'semibold', color: DesignTokens.colors.textPrimary }}>{item}</span>
            </div>
          ))}
        </div>

        {/* Source Code Note */}
        <div style={{ marginTop: '40px', textAlign: 'center', padding: '20px', background: 'rgba(0,0,0,0.05)', borderRadius: '12px' }}>
          <p style={{ margin: 0, fontSize: '14px', color: '#666' }}>
            Viewing <b>PocketPaws</b> Swift Reference Files:<br/>
            DesignTokens.swift, PetPalTheme.swift, Models.swift, MockData.swift
          </p>
        </div>

      </div>
    </div>
  );
};

const root = createRoot(document.getElementById('root')!);
root.render(<App />);
