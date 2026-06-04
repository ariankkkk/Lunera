# Lunera Agent Instructions

## Purpose
Lunera is a SwiftUI fashion app for personalized clothing discovery, store stock awareness, and event-based outfit recommendations. Future work should preserve the current polished native iOS prototype while moving it toward a Supabase-backed, AI-assisted product.

## Read First
Before changing code, inspect these docs in order:

1. `Docs/PRODUCT_SPEC.md`
2. `Docs/ARCHITECTURE.md`
3. `Docs/DATA_MODEL.md`
4. `Docs/AI_RECOMMENDATION_SPEC.md`
5. `Docs/DESIGN_SYSTEM.md`
6. `Docs/TASK_TEMPLATE.md`

If a requested change conflicts with these docs, update the docs in the same change or ask for direction.

## SwiftUI Conventions
- Keep SwiftUI views small, feature-scoped, and named by product behavior.
- Prefer native SwiftUI APIs, async/await, and value types.
- Keep app state out of view bodies when it becomes shared, persisted, or testable.
- Treat `Lunera/Core` as shared infrastructure and `Lunera/Features` as feature-owned UI and logic.
- Preserve the light, fashion-forward visual baseline unless the user explicitly asks for a redesign.

## Backend And AI Rules
- Supabase is the backend: Auth, Postgres, Storage, Edge Functions, and optional Realtime.
- OpenAI calls must happen from Supabase Edge Functions or another trusted server boundary, never directly from Swift.
- Do not commit API keys, service role keys, access tokens, cookies, or scraper credentials.
- Public Supabase tables must have Row Level Security enabled before exposing client access.
- Use structured JSON contracts for AI outputs. Do not rely on free-form AI text for app state.
- Deterministic recommendation scoring decides ranking. AI can parse event context and write explanations, but it must not be the only source of truth.

## Inventory And Scraping Rules
- V1 market is Baku stores.
- Scraping is allowed only after a source-specific robots/ToS check is documented.
- Every scraper must have rate limits, dry-run fixture tests, stale-stock behavior, and a manual fallback.
- Store inventory is a snapshot, not a guarantee. UI copy must avoid promising exact availability.

## Build And Verification
Use this smoke build after Swift/Xcode changes:

```sh
xcodebuild -project Lunera.xcodeproj -scheme Lunera -configuration Debug -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

For docs-only changes, verify links, filenames, and task templates. Do not run migrations or deploy Edge Functions unless the task explicitly asks for it.

## Git Hygiene
- Keep generated `.DS_Store`, Xcode user state, DerivedData, and build outputs out of git.
- Prefer focused commits with behavior-level messages.
- Do not revert user changes unless the user explicitly asks.

