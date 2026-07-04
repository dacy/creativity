import Database from "better-sqlite3";
import fs from "fs";
import path from "path";
import type { Idea, IdeaStatus, PreferenceProfile } from "./types";

const DATA_DIR = path.join(process.cwd(), "data");

let db: Database.Database | null = null;

export function getDb(): Database.Database {
  if (db) return db;
  fs.mkdirSync(DATA_DIR, { recursive: true });
  db = new Database(path.join(DATA_DIR, "spark.db"));
  db.pragma("journal_mode = WAL");
  db.exec(`
    CREATE TABLE IF NOT EXISTS ideas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      category TEXT NOT NULL DEFAULT 'general',
      duration_minutes INTEGER,
      criteria TEXT NOT NULL DEFAULT '',
      status TEXT NOT NULL DEFAULT 'pending',
      source TEXT NOT NULL DEFAULT 'ai',
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      decided_at TEXT
    );

    CREATE TABLE IF NOT EXISTS profile (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      content TEXT NOT NULL DEFAULT '',
      swipe_count INTEGER NOT NULL DEFAULT 0,
      updated_at TEXT
    );

    INSERT OR IGNORE INTO profile (id, content, swipe_count) VALUES (1, '', 0);
  `);
  return db;
}

export function insertIdeas(
  ideas: Array<{
    title: string;
    description: string;
    category: string;
    duration_minutes: number | null;
    criteria: string;
    source: "ai" | "mock";
  }>
): Idea[] {
  const d = getDb();
  const stmt = d.prepare(
    `INSERT INTO ideas (title, description, category, duration_minutes, criteria, source)
     VALUES (@title, @description, @category, @duration_minutes, @criteria, @source)`
  );
  const inserted: Idea[] = [];
  const tx = d.transaction(() => {
    for (const idea of ideas) {
      const result = stmt.run(idea);
      inserted.push(
        d
          .prepare("SELECT * FROM ideas WHERE id = ?")
          .get(result.lastInsertRowid) as Idea
      );
    }
  });
  tx();
  return inserted;
}

export function setIdeaStatus(id: number, status: IdeaStatus): Idea | null {
  const d = getDb();
  d.prepare(
    "UPDATE ideas SET status = ?, decided_at = datetime('now') WHERE id = ?"
  ).run(status, id);
  if (status === "liked" || status === "disliked") {
    d.prepare("UPDATE profile SET swipe_count = swipe_count + 1 WHERE id = 1").run();
  }
  return (d.prepare("SELECT * FROM ideas WHERE id = ?").get(id) as Idea) ?? null;
}

export function getIdeasByStatus(status: IdeaStatus, limit = 100): Idea[] {
  return getDb()
    .prepare(
      "SELECT * FROM ideas WHERE status = ? ORDER BY decided_at DESC, id DESC LIMIT ?"
    )
    .all(status, limit) as Idea[];
}

/** Recent decided ideas (liked + disliked), newest first — the AI's observation window. */
export function getRecentDecidedIdeas(limit = 40): Idea[] {
  return getDb()
    .prepare(
      `SELECT * FROM ideas WHERE status IN ('liked','disliked')
       ORDER BY decided_at DESC, id DESC LIMIT ?`
    )
    .all(limit) as Idea[];
}

/** All titles ever shown — used to avoid recommending duplicates. */
export function getAllIdeaTitles(limit = 200): string[] {
  return (
    getDb()
      .prepare("SELECT title FROM ideas ORDER BY id DESC LIMIT ?")
      .all(limit) as Array<{ title: string }>
  ).map((r) => r.title);
}

export function getProfile(): PreferenceProfile {
  return getDb()
    .prepare("SELECT content, swipe_count, updated_at FROM profile WHERE id = 1")
    .get() as PreferenceProfile;
}

export function saveProfile(content: string): void {
  getDb()
    .prepare(
      "UPDATE profile SET content = ?, updated_at = datetime('now') WHERE id = 1"
    )
    .run(content);
}
