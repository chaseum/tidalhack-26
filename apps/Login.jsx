import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { loginUser } from './apiClient';

function LoginPage() {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (event) => {
    event.preventDefault();
    setLoading(true);
    setError('');

    try {
      const result = await loginUser({ email, password });
      localStorage.setItem('petapp_auth_token', result.token);
      localStorage.setItem('petapp_auth_user', JSON.stringify(result.user));
      navigate('/home');
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Login failed';
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="page-shell">
      <section className="card" style={{ maxWidth: 420, margin: '0 auto' }}>
        <h1 className="page-header" style={{ fontSize: '1.6rem' }}>Login</h1>
        <p className="muted">Sign in with email and password.</p>

        <form className="stack" onSubmit={handleSubmit}>
          <div>
            <label htmlFor="loginEmail">Email</label>
            <input
              id="loginEmail"
              type="email"
              required
              value={email}
              onChange={(event) => setEmail(event.target.value)}
            />
          </div>

          <div>
            <label htmlFor="loginPassword">Password</label>
            <input
              id="loginPassword"
              type="password"
              required
              minLength={8}
              value={password}
              onChange={(event) => setPassword(event.target.value)}
            />
          </div>

          {error && <p style={{ color: 'var(--danger)', margin: 0 }}>{error}</p>}

          <button className="button" type="submit" disabled={loading}>
            {loading ? 'Signing in...' : 'Sign In'}
          </button>
        </form>

        <p className="small muted" style={{ marginTop: 12, marginBottom: 0 }}>
          Need an account? <Link to="/register">Create one</Link>
        </p>
      </section>
    </main>
  );
}

export default LoginPage;
