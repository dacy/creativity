import { NextResponse } from "next/server";
import { inferPreferenceProfile } from "@/lib/ai";
import {
  getProfile,
  getRecentDecidedIdeas,
  saveProfile,
  setIdeaStatus,
} from "@/lib/db";

export const runtime = "nodejs";

/** Re-infer the taste profile every N decisive swipes. */
const PROFILE_UPDATE_INTERVAL = 4;

export async function POST(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const ideaId = Number(id);
  if (!Number.isInteger(ideaId)) {
    return NextResponse.json({ error: "Invalid idea id" }, { status: 400 });
  }

  let body: { decision?: string };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const decision = body.decision;
  if (decision !== "liked" && decision !== "disliked" && decision !== "skipped") {
    return NextResponse.json(
      { error: "decision must be 'liked', 'disliked', or 'skipped'" },
      { status: 400 }
    );
  }

  const idea = setIdeaStatus(ideaId, decision);
  if (!idea) {
    return NextResponse.json({ error: "Idea not found" }, { status: 404 });
  }

  // Periodically re-infer the taste profile from observed behavior.
  // Done inline (awaited) so serverless-style runtimes don't kill the work,
  // but failures never block the swipe itself.
  let profileUpdated = false;
  const profile = getProfile();
  if (
    decision !== "skipped" &&
    profile.swipe_count > 0 &&
    profile.swipe_count % PROFILE_UPDATE_INTERVAL === 0
  ) {
    try {
      const updated = await inferPreferenceProfile(
        profile.content,
        getRecentDecidedIdeas(40)
      );
      if (updated) {
        saveProfile(updated);
        profileUpdated = true;
      }
    } catch (err) {
      console.error("profile inference failed:", err);
    }
  }

  return NextResponse.json({ idea, profileUpdated });
}
