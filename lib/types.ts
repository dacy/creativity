export type IdeaStatus = "pending" | "liked" | "disliked" | "skipped";

export interface Idea {
  id: number;
  title: string;
  description: string;
  category: string;
  duration_minutes: number | null;
  criteria: string;
  status: IdeaStatus;
  source: "ai" | "mock";
  created_at: string;
  decided_at: string | null;
}

export interface PreferenceProfile {
  content: string;
  swipe_count: number;
  updated_at: string | null;
}

export interface GeneratedIdea {
  title: string;
  description: string;
  category: string;
  duration_minutes: number | null;
}
