"use client";

import { useEffect, useState } from "react";
import type { PreferenceProfile } from "@/lib/types";

export default function ProfilePage() {
  const [profile, setProfile] = useState<PreferenceProfile | null>(null);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    fetch("/api/profile")
      .then((r) => r.json())
      .then((d) => setProfile(d.profile ?? null))
      .catch(() => setProfile(null))
      .finally(() => setLoaded(true));
  }, []);

  return (
    <div>
      <h1>What Spark thinks you like</h1>
      <p className="subtitle">
        This profile is inferred purely from your swipes — Spark never asks,
        it just watches. It's re-analyzed every few swipes and fed back into
        the idea generator.
      </p>

      {!loaded && (
        <div className="empty-state">
          <span className="spinner" />
        </div>
      )}

      {loaded && (!profile || !profile.content.trim()) && (
        <div className="empty-state">
          <p>
            No profile yet. Swipe on a handful of ideas and Spark will start
            forming a read on your taste.
            {profile ? ` (${profile.swipe_count} swipes so far)` : ""}
          </p>
        </div>
      )}

      {loaded && profile && profile.content.trim() && (
        <>
          <div className="profile-box">{profile.content}</div>
          <p className="profile-meta">
            Based on {profile.swipe_count} swipes · last updated{" "}
            {profile.updated_at ? `${profile.updated_at} UTC` : "never"}
          </p>
        </>
      )}
    </div>
  );
}
