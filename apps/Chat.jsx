import React, { useMemo, useState } from 'react';
import BottomNav from './BottomNav';
import { useApp } from './AppContext';

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

function assistantReply(userText, petName) {
  const lower = userText.toLowerCase();

  if (lower.includes('eating') || lower.includes('appetite')) {
    return `${petName}'s appetite changes should be tracked for 3-5 days. Log meals, energy, and stool quality in Pet Diary.`;
  }
  if (lower.includes('itch') || lower.includes('skin')) {
    return `For skin concerns, monitor scratching frequency, check for redness, and document bathing products. Add observations to Pet Diary and escalate to a vet if worsening.`;
  }
  if (lower.includes('walk') || lower.includes('exercise')) {
    return `A steady exercise rhythm helps mood and digestion. Try two short sessions and log behavior before and after each walk.`;
  }

  return `I can help build a care routine for ${petName}. Tell me symptoms, behavior changes, and recent routines. I will suggest what to track next.`;
}

function ChatPage() {
  const {
    state: { chatMessages, petProfile },
    actions,
  } = useApp();
  const [input, setInput] = useState('');
  const [lastSuggestedAction, setLastSuggestedAction] = useState(null);
  const [autoLogEnabled, setAutoLogEnabled] = useState(true);

  const suggestedPrompts = useMemo(
    () => [
      'My pet is scratching more than usual',
      'How often should I schedule dental cleaning?',
      'Help me build a weekly walk and bath routine',
    ],
    []
  );

  const sendMessage = (text) => {
    const trimmed = text.trim();
    if (!trimmed) return;

    actions.addChatMessage({ role: 'user', text: trimmed });

    const reply = assistantReply(trimmed, petProfile.name);
    actions.addChatMessage({ role: 'assistant', text: reply });

    const suggestedAction = inferSuggestedDiaryAction(trimmed);
    setLastSuggestedAction(suggestedAction);

    if (autoLogEnabled) {
      actions.addDiaryEntry({
        type: suggestedAction.type,
        date: new Date().toISOString().slice(0, 10),
        notes: suggestedAction.notes,
      });
    }
  };

  const handleSubmit = (event) => {
    event.preventDefault();
    sendMessage(input);
    setInput('');
  };

  const addSuggestionToDiary = () => {
    if (!lastSuggestedAction) return;
    actions.addDiaryEntry({
      type: lastSuggestedAction.type,
      date: new Date().toISOString().slice(0, 10),
      notes: lastSuggestedAction.notes,
    });
  };

  return (
    <main className="page-shell">
      <h1 className="page-header">Health Chat</h1>
      <p className="muted">
        Ask wellness questions about {petProfile.name}. Chat suggestions can be sent directly to the Pet Diary.
      </p>

      <section className="grid-two">
        <article className="card stack">
          <h2>Chatbot</h2>
          <div className="chat-list" style={{ maxHeight: 420, overflow: 'auto' }}>
            {chatMessages.map((message) => (
              <div key={message.id} className={`chat-item ${message.role}`}>
                <div className="small muted" style={{ textTransform: 'capitalize' }}>
                  {message.role}
                </div>
                <p style={{ marginBottom: 0 }}>{message.text}</p>
              </div>
            ))}
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
            <button className="button" type="submit">
              Send
            </button>
          </form>
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
