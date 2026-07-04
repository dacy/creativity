"use client";

import { useCallback, useRef, useState } from "react";
import SwipeCard, { type SwipeCardHandle } from "@/components/SwipeCard";
import type { Idea } from "@/lib/types";

const SUGGESTIONS = [
  "I have 30 minutes and want something fun",
  "Rainy afternoon, low energy, at home",
  "Something creative with my kids this weekend",
  "Free evening, want to learn something new",
  "Outdoors, under an hour, no spending",
];

export default function SwipePage() {
  const [criteria, setCriteria] = useState("");
  const [activeCriteria, setActiveCriteria] = useState<string | null>(null);
  const [queue, setQueue] = useState<Idea[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [mockMode, setMockMode] = useState(false);
  const [profileNote, setProfileNote] = useState(false);
  const fetching = useRef(false);
  const cardRef = useRef<SwipeCardHandle>(null);

  const fetchIdeas = useCallback(
    async (crit: string, replace: boolean) => {
      if (fetching.current) return;
      fetching.current = true;
      if (replace) setLoading(true);
      setError(null);
      try {
        const res = await fetch("/api/ideas/generate", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ criteria: crit, count: 3 }),
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || "Failed to get ideas");
        setMockMode(data.source === "mock");
        setQueue((q) => (replace ? data.ideas : [...q, ...data.ideas]));
      } catch (err) {
        setError(err instanceof Error ? err.message : "Something went wrong");
      } finally {
        fetching.current = false;
        setLoading(false);
      }
    },
    []
  );

  async function startSession(crit: string) {
    const trimmed = crit.trim();
    if (!trimmed) return;
    setActiveCriteria(trimmed);
    setQueue([]);
    await fetchIdeas(trimmed, true);
  }

  async function handleDecision(idea: Idea, decision: "liked" | "disliked") {
    setQueue((q) => q.filter((i) => i.id !== idea.id));

    // Keep the queue topped up in the background.
    if (activeCriteria && queue.length <= 2) {
      void fetchIdeas(activeCriteria, false);
    }

    try {
      const res = await fetch(`/api/ideas/${idea.id}/swipe`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ decision }),
      });
      const data = await res.json();
      if (data.profileUpdated) {
        setProfileNote(true);
        setTimeout(() => setProfileNote(false), 4000);
      }
    } catch {
      // A lost swipe record isn't worth interrupting the flow for.
    }
  }

  const current = queue[0];
  const next = queue[1];

  return (
    <div>
      <h1>What kind of thing are you in the mood for?</h1>
      <p className="subtitle">
        Describe your time, energy, and constraints. Swipe right on ideas you
        like, left on ones you don&apos;t — Spark learns your taste as you go.
      </p>

      <form
        className="criteria-form"
        onSubmit={(e) => {
          e.preventDefault();
          void startSession(criteria);
        }}
      >
        <textarea
          value={criteria}
          onChange={(e) => setCriteria(e.target.value)}
          placeholder="e.g. I have 30 minutes, I'm at home, medium energy, want something hands-on…"
        />
        <div className="chips">
          {SUGGESTIONS.map((s) => (
            <button
              key={s}
              type="button"
              className="chip"
              onClick={() => setCriteria(s)}
            >
              {s}
            </button>
          ))}
        </div>
        <button className="primary" type="submit" disabled={loading || !criteria.trim()}>
          {loading ? "Thinking…" : activeCriteria ? "New criteria, new ideas" : "Get ideas"}
        </button>
      </form>

      {mockMode && (
        <div className="notice">
          Running in <strong>mock mode</strong> — no ANTHROPIC_API_KEY is set,
          so these are canned sample ideas. Add a key to .env.local for real,
          personalized recommendations.
        </div>
      )}

      {profileNote && (
        <div className="notice">
          ✦ Spark just updated its read on your taste.{" "}
          <a href="/profile" style={{ color: "inherit" }}>
            See what it thinks →
          </a>
        </div>
      )}

      {error && <div className="notice">⚠ {error}</div>}

      {activeCriteria && (
        <>
          <div className="stack">
            {!current && loading && (
              <div className="empty-state">
                <span className="spinner" />
                <p style={{ marginTop: 12 }}>Dreaming up ideas…</p>
              </div>
            )}
            {!current && !loading && (
              <div className="empty-state">
                <p>Out of ideas for now — more are on the way, or tweak your criteria.</p>
              </div>
            )}
            {next && (
              <div
                className="card"
                style={{ transform: "scale(0.95) translateY(12px)", zIndex: 1 }}
              >
                <div className="meta">
                  <span className="tag">{next.category}</span>
                </div>
                <h2>{next.title}</h2>
              </div>
            )}
            {current && (
              <SwipeCard
                key={current.id}
                ref={cardRef}
                idea={current}
                interactive
                onDecision={(d) => void handleDecision(current, d)}
              />
            )}
          </div>

          {current && (
            <div className="actions">
              <button
                className="nope-btn"
                aria-label="Dislike"
                onClick={() => cardRef.current?.fly("disliked")}
              >
                ✕
              </button>
              <button
                className="like-btn"
                aria-label="Like"
                onClick={() => cardRef.current?.fly("liked")}
              >
                ♥
              </button>
            </div>
          )}
          <p className="hint">Drag the card or use the buttons · ✕ pass · ♥ keep</p>
        </>
      )}
    </div>
  );
}
