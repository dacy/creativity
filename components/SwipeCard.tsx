"use client";

import { useImperativeHandle, useRef, useState, type Ref } from "react";
import type { Idea } from "@/lib/types";

const SWIPE_THRESHOLD = 110;

export interface SwipeCardHandle {
  fly: (decision: "liked" | "disliked") => void;
}

export default function SwipeCard({
  idea,
  onDecision,
  interactive,
  ref,
}: {
  idea: Idea;
  onDecision: (decision: "liked" | "disliked") => void;
  interactive: boolean;
  ref?: Ref<SwipeCardHandle>;
}) {
  const [drag, setDrag] = useState({ x: 0, y: 0 });
  const [dragging, setDragging] = useState(false);
  const [flyingOut, setFlyingOut] = useState<null | "liked" | "disliked">(null);
  const start = useRef({ x: 0, y: 0 });
  const committed = useRef(false);

  function fly(decision: "liked" | "disliked") {
    if (committed.current) return;
    committed.current = true;
    setFlyingOut(decision);
    setDrag((d) => ({ x: decision === "liked" ? 600 : -600, y: d.y }));
    setTimeout(() => onDecision(decision), 220);
  }

  useImperativeHandle(ref, () => ({ fly }));

  function onPointerDown(e: React.PointerEvent) {
    if (!interactive || flyingOut) return;
    (e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
    start.current = { x: e.clientX, y: e.clientY };
    setDragging(true);
  }

  function onPointerMove(e: React.PointerEvent) {
    if (!dragging) return;
    setDrag({
      x: e.clientX - start.current.x,
      y: e.clientY - start.current.y,
    });
  }

  function onPointerUp() {
    if (!dragging) return;
    setDragging(false);
    if (drag.x > SWIPE_THRESHOLD) {
      fly("liked");
    } else if (drag.x < -SWIPE_THRESHOLD) {
      fly("disliked");
    } else {
      setDrag({ x: 0, y: 0 });
    }
  }

  const rotation = drag.x / 18;
  const likeOpacity = Math.min(Math.max(drag.x / SWIPE_THRESHOLD, 0), 1);
  const nopeOpacity = Math.min(Math.max(-drag.x / SWIPE_THRESHOLD, 0), 1);

  return (
    <div
      className={`card ${dragging ? "dragging" : "settling"}`}
      style={{
        transform: `translate(${drag.x}px, ${drag.y * 0.4}px) rotate(${rotation}deg)`,
        opacity: flyingOut ? 0 : 1,
        zIndex: 2,
      }}
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={onPointerUp}
      onPointerCancel={onPointerUp}
    >
      <span className="stamp like" style={{ opacity: likeOpacity }}>
        LIKE
      </span>
      <span className="stamp nope" style={{ opacity: nopeOpacity }}>
        NOPE
      </span>
      <div className="meta">
        <span className="tag">{idea.category}</span>
        {idea.duration_minutes ? (
          <span className="tag time">~{idea.duration_minutes} min</span>
        ) : null}
      </div>
      <h2>{idea.title}</h2>
      <p>{idea.description}</p>
    </div>
  );
}
