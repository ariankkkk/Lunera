# Lunera Architecture

## System Shape
Lunera is a SwiftUI iOS app backed by Supabase. Supabase stores users, catalog data, stock snapshots, events, recommendations, and feedback. Supabase Edge Functions handle trusted operations such as OpenAI calls and inventory ingestion.

```mermaid
flowchart LR
    User["iPhone user"] --> App["SwiftUI app"]
    App --> Auth["Supabase Auth"]
    App --> DB["Supabase Postgres"]
    App --> Storage["Supabase Storage"]
    App --> Functions["Supabase Edge Functions"]
    Functions --> OpenAI["OpenAI Structured Outputs"]
    Functions --> Scrapers["Store scraper adapters"]
    Scrapers --> StoreSites["Baku store sites"]
    Functions --> DB
```

## App Layers
- `Lunera/App`: entry point, routing, tab shell, app-wide composition.
- `Lunera/Core`: design system, networking clients, shared models, utilities, persistence adapters.
- `Lunera/Features`: feature-owned views and view models for auth, home, preferences, events, recommendations, and inventory.
- `Lunera/Resources`: asset catalogs and preview assets.
- `Lunera/Supporting`: app configuration.

## Backend Services
- Auth: Supabase Auth for account identity.
- Postgres: canonical product, preference, event, stock, and recommendation data.
- Storage: garment images, event images, profile avatars, and source assets that need remote storage.
- Edge Functions: trusted AI and ingestion operations.
- Realtime: optional future updates for stock ingestion progress or recommendation status.

## AI Boundary
The iOS app never calls OpenAI directly. It calls Supabase Edge Functions with user/session context. Edge Functions call OpenAI using Structured Outputs so responses match a JSON schema and can be safely decoded.

AI responsibilities:
- Parse event descriptions into structured context.
- Generate concise, user-facing explanations.
- Optionally normalize fuzzy user preference language.

Non-AI responsibilities:
- Ranking recommendations.
- Enforcing stock rules.
- Enforcing authorization.
- Persisting app state.

## Recommendation Data Flow
```mermaid
sequenceDiagram
    participant App as SwiftUI App
    participant Fn as Edge Function
    participant DB as Supabase Postgres
    participant AI as OpenAI

    App->>Fn: Request event outfit recommendation
    Fn->>DB: Fetch user preferences, garments, stores, stock
    Fn->>AI: Parse event context with JSON schema
    AI-->>Fn: Structured event context
    Fn->>Fn: Deterministic hybrid scoring
    Fn->>AI: Generate explanation with ranked items
    AI-->>Fn: Structured explanation
    Fn->>DB: Save recommendation
    Fn-->>App: Recommendation response
```

## Inventory Data Flow
```mermaid
flowchart LR
    SourceRegistry["Source registry"] --> Adapter["Scraper adapter"]
    Adapter --> DryRun["Fixture dry-run tests"]
    Adapter --> LiveFetch["Rate-limited live fetch"]
    LiveFetch --> Normalize["Normalize sizes and stock states"]
    Normalize --> Snapshot["stock_snapshots"]
    Snapshot --> App["Store availability UI"]
```

## Local Cache Strategy
Use Supabase as the source of truth. Use local persistence for responsive UI, recently viewed items, drafts, cached preferences, and offline-friendly display. SwiftData is acceptable for app-owned cache and drafts, but server sync logic should stay behind repositories so it can be tested and replaced.

## Security Defaults
- Enable RLS on all public schema tables.
- User-owned rows require `auth.uid()` ownership checks.
- Catalog rows can be readable by authenticated users.
- Service role operations are restricted to Edge Functions.
- Secrets live in Supabase secrets or local developer config, never in git.

