import { NextResponse } from "next/server";
import { generateIdeas } from "@/lib/ai";
import {
  getAllIdeaTitles,
  getIdeasByStatus,
  getProfile,
  insertIdeas,
} from "@/lib/db";

export const runtime = "nodejs";

export async function POST(request: Request) {
  let body: { criteria?: string; count?: number };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const criteria = (body.criteria ?? "").trim();
  if (!criteria) {
    return NextResponse.json(
      { error: "criteria is required" },
      { status: 400 }
    );
  }
  const count = Math.min(Math.max(body.count ?? 3, 1), 5);

  try {
    const profile = getProfile();
    const { ideas, source } = await generateIdeas({
      criteria,
      profile: profile.content,
      likedTitles: getIdeasByStatus("liked", 15).map((i) => i.title),
      dislikedTitles: getIdeasByStatus("disliked", 15).map((i) => i.title),
      seenTitles: getAllIdeaTitles(150),
      count,
    });

    const saved = insertIdeas(
      ideas.map((i) => ({
        title: i.title,
        description: i.description,
        category: i.category || "general",
        duration_minutes: i.duration_minutes ?? null,
        criteria,
        source,
      }))
    );

    return NextResponse.json({ ideas: saved, source });
  } catch (err) {
    console.error("generate failed:", err);
    const message =
      err instanceof Error ? err.message : "Idea generation failed";
    return NextResponse.json({ error: message }, { status: 502 });
  }
}
