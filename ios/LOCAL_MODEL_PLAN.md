# Plan: a real on-device LLM for phones without Apple Intelligence

## Goal

Spark should generate genuinely intelligent activity ideas on **any** iPhone,
not just Apple Intelligence-capable ones (iPhone 15 Pro+). Today the fallback
when `FoundationModels` is unavailable is `MockIdeaGenerator` — canned ideas
with no real reasoning. This plan adds a **bundled/downloaded local LLM** as a
first-class generator so the "no Apple Intelligence" path is still smart. Mock
mode stays only as a last resort (model still downloading, device too small,
runtime failure).

Everything stays local — this changes *which* on-device model runs, not the
privacy model. No network calls for inference; the only network use is a
one-time model **download**, and the only data that ever leaves the device is
still the user-initiated export.

## Where it plugs in

The architecture already supports this cleanly. `IdeaGenerating` is the seam:

```
GeneratorFactory.make() picks the best available tier:
  1. FoundationModelGenerator   — Apple Intelligence (iPhone 15 Pro+, iOS 26)
  2. LocalLLMGenerator          — NEW: bundled/downloaded llama.cpp model
  3. MockIdeaGenerator          — last resort (downloading / tiny device / error)
```

No UI or view-model changes are required beyond richer status messaging —
`LocalLLMGenerator` just conforms to the same protocol (`generateIdeas` +
`inferProfile` + `sourceLabel`).

## Engine choice

**Primary recommendation: llama.cpp + Metal, with GBNF grammar-constrained
JSON.**

| Option | Pros | Cons |
|---|---|---|
| **llama.cpp** (via SwiftPM xcframework or a wrapper like `LLM.swift` / `SpeziLLM`) | Mature, Metal-accelerated, huge GGUF model selection, **GBNF grammar guarantees valid JSON** (the on-device equivalent of the web app's JSON-schema output) | C interop; manual memory management |
| **MLX Swift** (`mlx-swift-examples`) | Apple-native, excellent perf on Apple GPUs, future-proof | Constrained/structured decoding is DIY — no turnkey grammar, so we'd prompt-and-repair |
| **MediaPipe LLM Inference** (Google) | Clean Swift API, handles device details | Prompt-and-parse only; fewer models (Gemma/Phi) |

GBNF is the deciding factor: it gives us **guaranteed-parseable JSON** the same
way `@Generable` guided generation does on Apple's model, so we don't
reintroduce the fragile string-parsing the web app avoided. MLX is the strong
runner-up if we later want a more Apple-native stack.

## Model choice (tiered by device RAM)

Creative brainstorming + short structured output is forgiving; a 1.5B–3B 4-bit
instruct model is the sweet spot. Prefer **Apache-2.0 models** (Qwen2.5) for
clean redistribution.

| Device RAM | Example devices (no Apple Intelligence) | Model | ~Size (Q4_K_M) |
|---|---|---|---|
| 6 GB+ | iPhone 15 / 15 Plus (A16), iPhone 14 line | Qwen2.5-3B-Instruct | ~1.9 GB |
| 4 GB | iPhone 11/12/13, SE 3 | Qwen2.5-1.5B-Instruct | ~1.0 GB |
| 3 GB / very old | SE 2, iPhone XR-era | (stay on mock) | — |

Licensing: **Qwen2.5 is Apache-2.0** → easy to host/redistribute. Llama 3.2
1B/3B is a fine quality alternative but carries Meta's community license — bundle
its license text and check redistribution terms if chosen.

Selection at runtime: read `ProcessInfo.processInfo.physicalMemory`, pick the
tier, and let the user override in Settings.

## Delivery: download, don't bundle

A ~2 GB model in the app binary bloats the App Store download and update size.
Instead:

- **Download on first run** from a CDN or Hugging Face into
  `Application Support/Models/`, excluded from iCloud backup
  (`URLResourceValues.isExcludedFromBackup = true`).
- Show a **progress UI** ("Downloading on-device model — 640 MB / 1.9 GB"); the
  app is fully usable in mock mode during the download.
- Verify a **SHA-256 checksum** after download; support resume, delete, and
  re-download from Settings.
- Optional: ship a tiny (~0.5B) model in the bundle so there's *some* real
  generation offline immediately, upgrading to the larger model after download.

## Structured output

Define GBNF grammars mirroring the existing `@Generable` shapes:

- `IdeaBatch` grammar → `{ "ideas": [ { "title", "details", "category",
  "durationMinutes" } x N ] }`
- `Profile` grammar → `{ "profile": "…" }`

llama.cpp enforces the grammar during decoding, so output is always valid JSON.
Reuse the current prompt builder from `FoundationModelGenerator` almost verbatim
(instructions + criteria + profile + liked/disliked/seen titles). Keep prompts
compact — small models have small context windows and slower prefill.

## Memory & performance hardening

The real risk on iPhone is **jetsam (OS killing the app for memory)**:

- Load the model **lazily** on first generation; keep **one** llama context.
- **Unload on memory pressure** (`UIApplication.didReceiveMemoryWarningNotification`)
  and when backgrounded; reload on demand.
- Run inference **off the main actor** (llama.cpp calls block) on a dedicated
  serial executor; stream tokens so the UI shows progress.
- Keep `batchSize` small (already 3) and cap context to bound KV-cache memory.
- **Cancel** in-flight generation when the user swipes past / changes criteria.
- Watch thermals/battery: don't pre-generate aggressively; the existing
  "top up when queue ≤ 2" throttle is good.
- If generation OOMs or throws, fall back to mock for that request (same
  runtime-fallback pattern already added for `FoundationModelGenerator`).

## Phased implementation

- **Phase 0 — decisions.** Confirm engine (llama.cpp), model (Qwen2.5 3B/1.5B),
  hosting location, license text. Lock the download URL + checksums.
- **Phase 1 — engine spike.** Add the llama.cpp dependency; load a model from a
  hardcoded path; generate raw text on a physical device. Prove tokens flow and
  measure tok/s + memory on a 6 GB and a 4 GB device.
- **Phase 2 — `LocalLLMGenerator`.** Implement the protocol with GBNF-constrained
  `generateIdeas` + `inferProfile`; wire it into `GeneratorFactory` as tier 2.
- **Phase 3 — model manager.** First-run download with progress, checksum,
  resume, storage, RAM-tiered selection, delete/redownload.
- **Phase 4 — memory/perf hardening.** Lazy load/unload, memory-warning
  handling, streaming, cancellation, thermal care.
- **Phase 5 — UX/Settings.** A Settings screen showing the active engine
  ("Apple Intelligence" / "On-device model — Qwen 3B" / "Sample mode") and
  download controls; update banners to reflect the three tiers.
- **Phase 6 — device-matrix validation.** Test on: Apple Intelligence device
  (tier 1), 6 GB non-AI device (tier 2 large), 4 GB device (tier 2 small),
  and a 3 GB/old device (mock). Verify JSON validity, latency, memory ceiling,
  battery/thermals.

## Risks & mitigations

| Risk | Mitigation |
|---|---|
| Jetsam on 4 GB devices | RAM-tiered model, unload on pressure, cap context; mock below 4 GB |
| App Store size | Download model post-install, not bundled |
| Model license/redistribution | Prefer Apache-2.0 (Qwen2.5); host ourselves; ship license text |
| Slower than Apple's model | Stream + spinner; small batches; keep queue topped up |
| JSON reliability | GBNF grammar guarantees valid JSON; parse-repair fallback |
| Battery/thermals | Throttle pre-generation; cancel unused work |

## Explicitly out of scope (for now)

- A remote-API fallback (would break the local-first promise; the user can
  already export insights to any external LLM manually).
- Fine-tuning / on-device training.
- Multiple concurrent models.

## Validation note

This environment has no Xcode, so all of the above must be built and measured on
a Mac + physical devices. Phase 1's on-device tok/s and memory numbers should
gate the model-size choices in Phase 0.
