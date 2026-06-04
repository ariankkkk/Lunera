# Lunera Roadmap

## Phase 1: AI Factory Docs And Schema Plan
- Add product, architecture, data model, AI, scraping, event, design, task, and eval docs.
- Keep implementation docs lean and current.
- Prepare first Supabase migration from `Docs/DATA_MODEL.md`.

Done when an agent can start a feature from `Docs/TASK_TEMPLATE.md` without extra product explanation.

## Phase 2: Supabase Integration
- Add Supabase Swift package.
- Create client configuration with publishable key only.
- Implement auth session handling.
- Add repositories for profiles, preferences, garments, events, and recommendations.
- Create RLS-enabled schema migrations.

Done when a signed-in user can load and save profile/preferences.

## Phase 3: Preference Capture
- Replace static onboarding preference rows with real inputs.
- Persist user preferences.
- Add preference summary and edit flow.
- Add fixture tests for preference normalization.

Done when preferences affect recommendation scoring.

## Phase 4: Inventory Ingestion
- Create source registry for Baku stores.
- Build scraper adapter dry-run fixtures.
- Implement `ingest-store-stock` Edge Function after compliance review.
- Store stock snapshots and display freshness.

Done when stock can be imported from at least one approved/manual source.

## Phase 5: Hybrid Recommendation Engine
- Implement deterministic scoring.
- Add debug scoring endpoint.
- Add fixture tests for scoring weights and penalties.
- Add feedback capture.

Done when recommendations are reproducible from stored inputs.

## Phase 6: Event Intelligence
- Implement `parse-event-context`.
- Implement event recommendation generation.
- Render saved event recommendations in the SwiftUI event flow.
- Add failure and partial-result states.

Done when a user can describe an event and receive a ranked outfit with reasons and stock warnings.

## Phase 7: Testing And Analytics
- Add unit tests for models, repositories, scoring, and schema decoding.
- Add scraper dry-run tests.
- Add lightweight analytics for recommendation viewed, saved, liked, disliked, and stock warning shown.
- Run Supabase advisors after schema changes.

Done when product quality can be measured without relying on manual screenshots only.

