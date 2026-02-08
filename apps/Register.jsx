import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { registerUser } from './apiClient';

function RegisterPage() {
  const navigate = useNavigate();
  const [displayName, setDisplayName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (event) => {
    event.preventDefault();
    setError('');

    if (password !== confirmPassword) {
      setError('Passwords do not match');
      return;
    }

    setLoading(true);
    try {
      const result = await registerUser({ email, password, displayName });
      localStorage.setItem('petapp_auth_token', result.token);
      localStorage.setItem('petapp_auth_user', JSON.stringify(result.user));
      navigate('/home');
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Registration failed';
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="page-shell">
      <section className="card" style={{ maxWidth: 460, margin: '0 auto' }}>
        <h1 className="page-header" style={{ fontSize: '1.6rem' }}>Register</h1>
        <p className="muted">Create an account for pet wellness tracking.</p>

        <form className="stack" onSubmit={handleSubmit}>
          <div>
            <label htmlFor="registerName">Display Name</label>
            <input
              id="registerName"
              value={displayName}
              onChange={(event) => setDisplayName(event.target.value)}
              placeholder="Your name"
            />
          </div>

          <div>
            <label htmlFor="registerEmail">Email</label>
            <input
              id="registerEmail"
              type="email"
              required
              value={email}
              onChange={(event) => setEmail(event.target.value)}
            />
          </div>

          <div>
            <label htmlFor="registerPassword">Password</label>
            <input
              id="registerPassword"
              type="password"
              required
              minLength={8}
              value={password}
              onChange={(event) => setPassword(event.target.value)}
            />
          </div>

          <div>
            <label htmlFor="registerPassword2">Confirm Password</label>
            <input
              id="registerPassword2"
              type="password"
              required
              minLength={8}
              value={confirmPassword}
              onChange={(event) => setConfirmPassword(event.target.value)}
            />
          </div>

          {error && <p style={{ color: 'var(--danger)', margin: 0 }}>{error}</p>}

          <button className="button" type="submit" disabled={loading}>
            {loading ? 'Creating account...' : 'Create Account'}
          </button>
        </form>

        <p className="small muted" style={{ marginTop: 12, marginBottom: 0 }}>
          Already have an account? <Link to="/login">Sign in</Link>
        </p>
      </section>
    </main>
  );
}

export default RegisterPage;
