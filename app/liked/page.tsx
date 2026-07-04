"use client";

import { useEffect, useState } from "react";
import type { Idea } from "@/lib/types";

export default function LikedPage() {
  const [ideas, setIdeas] = useState<Idea[] | null>(null);

  useEffect(() => {
    fetch("/api/ideas/liked")
      .then((r) => r.json())
      .then((d) => setIdeas(d.ideas ?? []))
      .catch(() => setIdeas([]));
  }, []);

  return (
    <div>
      <h1>Ideas you kept</h1>
      <p className="subtitle">
        Your collection of liked ideas — pick one and actually do it.
      </p>

      {ideas === null && (
        <div className="empty-state">
          <span className="spinner" />
        </div>
      )}

      {ideas !== null && ideas.length === 0 && (
        <div className="empty-state">
          <p>Nothing saved yet. Go swipe right on something you like!</p>
        </div>
      )}

      {ideas !== null && ideas.length > 0 && (
        <div className="idea-list">
          {ideas.map((idea) => (
            <div key={idea.id} className="idea-item">
              <h3>{idea.title}</h3>
              <p>{idea.description}</p>
              <div className="meta">
                <span className="tag">{idea.category}</span>
                {idea.duration_minutes ? (
                  <span className="tag time">~{idea.duration_minutes} min</span>
                ) : null}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
