import Anthropic from "@anthropic-ai/sdk";
import type { GeneratedIdea, Idea } from "./types";

const MODEL = process.env.SPARK_MODEL || "claude-opus-4-8";

function hasCredentials(): boolean {
  return Boolean(
    process.env.ANTHROPIC_API_KEY || process.env.ANTHROPIC_AUTH_TOKEN
  );
}

let client: Anthropic | null = null;
function getClient(): Anthropic {
  if (!client) client = new Anthropic();
  return client;
}

function firstTextBlock(response: Anthropic.Message): string {
  const block = response.content.find((b) => b.type === "text");
  if (!block || block.type !== "text") {
    throw new Error("No text block in model response");
  }
  return block.text;
}

const IDEAS_SCHEMA = {
  type: "object",
  properties: {
    ideas: {
      type: "array",
      items: {
        type: "object",
        properties: {
          title: { type: "string" },
          description: { type: "string" },
          category: { type: "string" },
          duration_minutes: { type: ["integer", "null"] },
        },
        required: ["title", "description", "category", "duration_minutes"],
        additionalProperties: false,
      },
    },
  },
  required: ["ideas"],
  additionalProperties: false,
} as const;

const PROFILE_SCHEMA = {
  type: "object",
  properties: {
    profile: { type: "string" },
  },
  required: ["profile"],
  additionalProperties: false,
} as const;

export interface GenerateContext {
  criteria: string;
  profile: string;
  likedTitles: string[];
  dislikedTitles: string[];
  seenTitles: string[];
  count: number;
}

export async function generateIdeas(
  ctx: GenerateContext
): Promise<{ ideas: GeneratedIdea[]; source: "ai" | "mock" }> {
  if (!hasCredentials()) {
    return { ideas: mockIdeas(ctx), source: "mock" };
  }

  const sections: string[] = [];
  sections.push(`The user's current criteria/constraints:\n${ctx.criteria}`);
  if (ctx.profile.trim()) {
    sections.push(
      `What you have inferred about this user's taste from watching their past reactions (treat this as strong guidance):\n${ctx.profile}`
    );
  }
  if (ctx.likedTitles.length) {
    sections.push(`Ideas they LIKED recently:\n- ${ctx.likedTitles.join("\n- ")}`);
  }
  if (ctx.dislikedTitles.length) {
    sections.push(
      `Ideas they REJECTED recently:\n- ${ctx.dislikedTitles.join("\n- ")}`
    );
  }
  if (ctx.seenTitles.length) {
    sections.push(
      `Ideas already shown — do NOT repeat these or near-duplicates:\n- ${ctx.seenTitles.join("\n- ")}`
    );
  }
  sections.push(
    `Generate exactly ${ctx.count} activity ideas. Each idea should be concrete and immediately actionable (the user could start it right now), fit the criteria, and be genuinely creative — avoid generic filler like "take a walk" unless the criteria strongly point there. Vary the ideas across different categories so swipes reveal taste. Keep each description to 2-3 sentences explaining what to do and why it's interesting. Set duration_minutes to your best estimate, or null if open-ended.`
  );

  const response = await getClient().messages.create({
    model: MODEL,
    max_tokens: 4000,
    thinking: { type: "adaptive" },
    system:
      "You are the recommendation engine of an activity-idea app. The user swipes right (like) or left (dislike) on your ideas, and you learn their taste over time. Your goal is to propose creative, specific, doable activities that fit the user's stated criteria and observed preferences.",
    messages: [{ role: "user", content: sections.join("\n\n") }],
    output_config: {
      format: { type: "json_schema", schema: IDEAS_SCHEMA },
    },
  });

  const parsed = JSON.parse(firstTextBlock(response)) as {
    ideas: GeneratedIdea[];
  };
  return { ideas: parsed.ideas.slice(0, ctx.count), source: "ai" };
}

/**
 * Re-infer the user's taste profile by observing their swipe history.
 * The model is asked to extract WHY the user likes/dislikes things,
 * not just list what they swiped on.
 */
export async function inferPreferenceProfile(
  currentProfile: string,
  recentDecisions: Idea[]
): Promise<string | null> {
  if (!hasCredentials() || recentDecisions.length === 0) return null;

  const history = recentDecisions
    .map(
      (i) =>
        `[${i.status === "liked" ? "LIKED" : "REJECTED"}] "${i.title}" (${i.category}${
          i.duration_minutes ? `, ~${i.duration_minutes} min` : ""
        }) — ${i.description}\n  criteria at the time: ${i.criteria || "(none)"}`
    )
    .join("\n");

  const response = await getClient().messages.create({
    model: MODEL,
    max_tokens: 2000,
    thinking: { type: "adaptive" },
    system:
      "You maintain a taste profile for a user of an activity-recommendation app, purely by observing which ideas they liked or rejected. You never ask the user questions — you infer.",
    messages: [
      {
        role: "user",
        content: `Current profile (may be empty):\n${currentProfile || "(empty)"}\n\nRecent swipe history, newest first:\n${history}\n\nUpdate the profile. Look for the underlying WHY behind likes and rejections: themes, energy level, social vs solo, indoor vs outdoor, creative vs analytical, cost sensitivity, time appetite, novelty vs comfort. Note both attractions and aversions. Where the evidence is thin, say so with hedged language rather than overclaiming. Write it as concise markdown with short sections (e.g. "Drawn to", "Avoids", "Patterns", "Open questions"), under 300 words. This text will be fed to the idea generator, so make it actionable.`,
      },
    ],
    output_config: {
      format: { type: "json_schema", schema: PROFILE_SCHEMA },
    },
  });

  const parsed = JSON.parse(firstTextBlock(response)) as { profile: string };
  return parsed.profile;
}

/** Canned ideas so the UI is fully usable without an API key. */
function mockIdeas(ctx: GenerateContext): GeneratedIdea[] {
  const pool: GeneratedIdea[] = [
    { title: "Blind contour self-portrait", description: "Draw your own face without looking at the paper or lifting the pen. The results are always hilariously wrong, which is the point — it trains observation and kills perfectionism.", category: "creative", duration_minutes: 15 },
    { title: "One-song kitchen dance mix", description: "Pick one song you loved as a teenager, play it loud, and cook or clean while it loops. Nostalgia plus movement is an instant mood shift.", category: "movement", duration_minutes: 10 },
    { title: "Micro photo essay", description: "Take exactly five photos that tell a story about the room you're in, then give the series a title. Constraints make it art instead of snapshots.", category: "creative", duration_minutes: 20 },
    { title: "Speedrun a Wikipedia rabbit hole", description: "Start at a random article and reach 'Philosophy' by clicking only in-article links. Time yourself. You'll learn three weird facts minimum.", category: "mental", duration_minutes: 15 },
    { title: "Letter to future you", description: "Write a short letter to yourself one year from now and schedule it with an email-later service. Takes ten minutes, pays off in a year.", category: "reflection", duration_minutes: 10 },
    { title: "Five-object still life", description: "Grab five random objects from around you and arrange them into the most dramatic still-life composition you can, then photograph it like a museum piece.", category: "creative", duration_minutes: 20 },
    { title: "Stairwell interval sprint", description: "Find the nearest stairs and do 8 rounds of up-fast, down-slow. A legit workout hiding in your building.", category: "fitness", duration_minutes: 15 },
    { title: "Learn a card flourish", description: "Pull up a tutorial for the 'charlier cut' one-handed card flourish and drill it. A pocket-sized skill that impresses forever.", category: "skill", duration_minutes: 25 },
    { title: "Sound map meditation", description: "Sit still, close your eyes, and mentally map every sound you can hear by direction and distance. It's mindfulness disguised as a spy exercise.", category: "reflection", duration_minutes: 10 },
    { title: "Haiku news digest", description: "Read three headlines, then summarize each as a haiku. Absurdly effective way to feel informed and amused at once.", category: "creative", duration_minutes: 15 },
    { title: "Text a micro-compliment", description: "Send three people one specific, true compliment each — not 'you're great' but 'the way you handled X was sharp'. Watch the replies roll in.", category: "social", duration_minutes: 10 },
    { title: "Desk-drawer archaeology", description: "Empty one drawer completely and treat every object as an artifact: keep, gift, or toss. You'll find at least one forgotten treasure.", category: "practical", duration_minutes: 20 },
  ];
  // Rotate through the pool so repeated calls don't return the same batch.
  const seen = new Set(ctx.seenTitles);
  const fresh = pool.filter((p) => !seen.has(p.title));
  return (fresh.length >= ctx.count ? fresh : pool).slice(0, ctx.count);
}
