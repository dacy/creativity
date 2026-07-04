# ✦ Spark — AI activity ideas that learn your taste

> **Two apps in this repo:** the original web app (this directory, Next.js +
> Claude API) and a local-first iOS app (`ios/`, SwiftUI + on-device Apple
> Intelligence model, all data stored on the phone). See [`ios/README.md`](ios/README.md).

Tell Spark your criteria ("I have 30 minutes, low energy, at home"), and it
deals you creative activity ideas one card at a time. Swipe right to keep an
idea, left to reject it — like a dating app, but for things to do.

The interesting part: **Spark learns by watching, not by asking.** Every few
swipes it sends your like/dislike history to Claude, which infers *why* you
react the way you do (energy level, solo vs. social, creative vs. analytical,
cost sensitivity, …) and writes that into a taste profile. That profile is fed
back into every future generation request, so recommendations steadily converge
on your actual preferences.

## Features

- **Criteria-driven generation** — free-text constraints (time, mood, place, budget)
- **Swipeable cards** — drag with mouse/touch or use the ♥ / ✕ buttons
- **Observed preference learning** — an AI-written taste profile, updated every
  4 decisive swipes, viewable on the *Your taste* page
- **Liked-ideas collection** — everything you swiped right on, in one list
- **Duplicate avoidance** — previously shown ideas are excluded from new batches
- **Mock mode** — no API key? The UI still works with canned sample ideas

## Getting started

```bash
npm install
cp .env.example .env.local   # add your ANTHROPIC_API_KEY
npm run dev
```

Open http://localhost:3000.

Without an `ANTHROPIC_API_KEY`, the app runs in mock mode (canned ideas, no
preference learning) so you can still try the swiping flow.

## How it works

```
criteria ──► POST /api/ideas/generate ──► Claude (claude-opus-4-8)
                    │                        ▲
                    ▼                        │ taste profile +
              SQLite (ideas)                 │ recent likes/dislikes +
                    │                        │ already-seen titles
   swipe ──► POST /api/ideas/:id/swipe ─────┘
                    │
                    ▼ every 4 swipes
             Claude infers an updated taste profile
             (stored in SQLite, shown at /profile)
```

- **Storage**: a local SQLite database at `data/spark.db` (created on first
  run). Two tables: `ideas` (every idea ever shown + its swipe outcome) and
  `profile` (the current AI-inferred taste profile).
- **Generation**: each request includes your criteria, the current taste
  profile, recent liked/rejected titles, and a list of already-seen titles so
  ideas don't repeat. Responses use structured JSON output so parsing is
  reliable.
- **Learning**: preference inference happens server-side after every 4th
  decisive swipe. The model is prompted to extract the *underlying why* and to
  hedge where evidence is thin.

## Roadmap ideas

- Export liked ideas (markdown / calendar)
- "Develop this idea" — expand a liked idea into a concrete plan with steps
- Multiple users / profiles
- Criteria presets and history
