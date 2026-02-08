import React, { useEffect, useMemo, useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import BottomNav from './BottomNav';
import { useApp } from './AppContext';
import { sendChatMessage as requestChatMessage } from './apiClient';

const CHAT_SESSION_KEY = 'petapp_chat_session_id_v1';

function inferSuggestedDiaryAction(text) {
  const lower = text.toLowerCase();

  if (lower.includes('walk')) {
    return { type: 'Walk', notes: 'Chat follow-up: planned a walk based on conversation.' };
  }
  if (lower.includes('bath') || lower.includes('wash')) {
    return { type: 'Bath', notes: 'Chat follow-up: bath/grooming reminder from assistant.' };
  }
  if (lower.includes('teeth') || lower.includes('dental')) {
    return { type: 'Dental Cleaning', notes: 'Chat follow-up: dental care reminder from assistant.' };
  }
  if (lower.includes('vet') || lower.includes('clinic')) {
    return { type: 'Vet Visit', notes: 'Chat follow-up: vet check discussion with assistant.' };
  }
  if (lower.includes('med') || lower.includes('medicine')) {
    return { type: 'Medication', notes: 'Chat follow-up: medication routine discussed with assistant.' };
  }

  return { type: 'Other', notes: 'Chat follow-up: general wellness recommendation added.' };
}

function getOrCreateChatSessionId() {
  const existing = localStorage.getItem(CHAT_SESSION_KEY);
  if (existing && existing.trim()) {
    return existing;
  }

  const generated = `chat-${Date.now()}-${Math.random().toString(16).slice(2, 10)}`;
  localStorage.setItem(CHAT_SESSION_KEY, generated);
  return generated;
}

function ChatPage() {
  const location = useLocation();
  const navigate = useNavigate();
  const {
    state: { chatMessages, petProfile },
    actions,
  } = useApp();

  const [input, setInput] = useState('');
  const [lastSuggestedAction, setLastSuggestedAction] = useState(null);
  const [autoLogEnabled, setAutoLogEnabled] = useState(true);
  const [backendQuickActions, setBackendQuickActions] = useState([]);
  const [chatError, setChatError] = useState('');
  const [isSending, setIsSending] = useState(false);
  const [chatSessionId, setChatSessionId] = useState(() => getOrCreateChatSessionId());

  useEffect(() => {
    const prefill = location.state?.prefill;
    if (typeof prefill === 'string' && prefill.trim()) {
      setInput(prefill.trim());
      navigate(location.pathname, { replace: true, state: null });
    }
  }, [location.pathname, location.state, navigate]);

  const suggestedPrompts = useMemo(
    () => [
      'My pet is scratching more than usual',
      'How often should I schedule dental cleaning?',
      'Help me build a weekly walk and bath routine',
    ],
    []
  );

  const sendMessage = async (text) => {
    const trimmed = text.trim();
    if (!trimmed || isSending) return;

    setChatError('');
    setIsSending(true);
    actions.addChatMessage({ role: 'user', text: trimmed });

    try {
      const response = await requestChatMessage({
        message: trimmed,
        sessionId: chatSessionId,
      });

      actions.addChatMessage({ role: 'assistant', text: response.reply });
      setBackendQuickActions(Array.isArray(response.quick_actions) ? response.quick_actions : []);

      const suggestedAction = inferSuggestedDiaryAction(trimmed);
      setLastSuggestedAction(suggestedAction);

      if (autoLogEnabled) {
        actions.addDiaryEntry({
          type: suggestedAction.type,
          date: new Date().toISOString().slice(0, 10),
          notes: suggestedAction.notes,
        });
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Could not reach assistant service.';
      setChatError(message);
      setBackendQuickActions([]);
      actions.addChatMessage({
        role: 'assistant',
        text: 'I could not reach the assistant right now. Please try again in a moment.',
      });
    } finally {
      setIsSending(false);
    }
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    const outbound = input;
    setInput('');
    await sendMessage(outbound);
  };

  const addSuggestionToDiary = () => {
    if (!lastSuggestedAction) return;
    actions.addDiaryEntry({
      type: lastSuggestedAction.type,
      date: new Date().toISOString().slice(0, 10),
      notes: lastSuggestedAction.notes,
    });
  };

  const resetChatSession = () => {
    const nextSession = `chat-${Date.now()}-${Math.random().toString(16).slice(2, 10)}`;
    localStorage.setItem(CHAT_SESSION_KEY, nextSession);
    setChatSessionId(nextSession);
    setBackendQuickActions([]);
    setChatError('');
  };

  return (
    <main className="page-shell">
      <h1 className="page-header">Health Coach</h1>
      <p className="muted">Ask wellness questions about {petProfile.name}. Messages are sent to backend /chat.</p>

      <section className="grid-two">
        <article className="card stack">
          <div style={{ display: 'flex', justifyContent: 'space-between', gap: 8, alignItems: 'center' }}>
            <h2 style={{ margin: 0 }}>Coach Chat</h2>
            <button type="button" className="button ghost" onClick={resetChatSession}>
              New session
            </button>
          </div>

          <div className="chat-list" style={{ maxHeight: 420, overflow: 'auto' }}>
            {chatMessages.map((message) => (
              <div key={message.id} className={`chat-item ${message.role}`}>
                <div className="small muted" style={{ textTransform: 'capitalize' }}>
                  {message.role}
                </div>
                <p style={{ marginBottom: 0 }}>{message.text}</p>
              </div>
            ))}
            {isSending && <p className="small muted">Assistant is thinking...</p>}
          </div>

          <form onSubmit={handleSubmit} className="stack">
            <label htmlFor="chatInput">Message</label>
            <textarea
              id="chatInput"
              rows={3}
              placeholder="Describe a symptom, behavior change, or routine question..."
              value={input}
              onChange={(event) => setInput(event.target.value)}
            />
            <button className="button" type="submit" disabled={isSending}>
              {isSending ? 'Sending...' : 'Send'}
            </button>
          </form>

          {chatError && <p style={{ color: 'var(--danger)', margin: 0 }}>{chatError}</p>}
        </article>

        <aside className="card stack">
          <h2>Quick prompts</h2>
          <label htmlFor="autoLogMode">Auto-log chat suggestions to Pet Diary</label>
          <select
            id="autoLogMode"
            value={autoLogEnabled ? 'on' : 'off'}
            onChange={(event) => setAutoLogEnabled(event.target.value === 'on')}
          >
            <option value="on">On</option>
            <option value="off">Off</option>
          </select>

          <div className="stack">
            {suggestedPrompts.map((prompt) => (
              <button key={prompt} type="button" className="button ghost" onClick={() => sendMessage(prompt)}>
                {prompt}
              </button>
            ))}
          </div>

          <div className="card" style={{ padding: 12 }}>
            <h3 style={{ marginBottom: 8 }}>Backend Quick Actions</h3>
            {backendQuickActions.length === 0 && (
              <p className="muted" style={{ margin: 0 }}>
                Send a message to receive quick actions from /chat.
              </p>
            )}
            <div className="stack">
              {backendQuickActions.map((action) => (
                <button key={action} type="button" className="button ghost" onClick={() => sendMessage(action)}>
                  {action}
                </button>
              ))}
            </div>
          </div>

          <div className="card" style={{ padding: 12 }}>
            <h3 style={{ marginBottom: 8 }}>Auto-add to Diary</h3>
            {!lastSuggestedAction && <p className="muted">Send a message first to generate a diary suggestion.</p>}
            {lastSuggestedAction && (
              <div className="stack">
                <p style={{ margin: 0 }}>
                  Suggested entry: <strong>{lastSuggestedAction.type}</strong>
                </p>
                <p className="small muted" style={{ margin: 0 }}>
                  {lastSuggestedAction.notes}
                </p>
                <button type="button" className="button secondary" onClick={addSuggestionToDiary}>
                  Add Suggestion To Pet Diary
                </button>
              </div>
            )}
          </div>
        </aside>
      </section>

      <BottomNav />
    </main>
  );
}

export default ChatPage;
