# Lunera Data Model

## Principles
- Supabase Postgres is the source of truth.
- Use stable UUID primary keys.
- Keep user-owned data separate from public catalog data.
- Enable RLS on every public table before client access.
- Store AI output as structured JSON plus denormalized display fields needed by the app.

## Core Entities

### `profiles`
User profile linked to Supabase Auth.

Fields:
- `id uuid primary key references auth.users(id)`
- `display_name text`
- `avatar_url text`
- `home_city text default 'Baku'`
- `created_at timestamptz`
- `updated_at timestamptz`

RLS:
- Users can select and update their own profile.

### `user_preferences`
Personal recommendation inputs.

Fields:
- `id uuid primary key`
- `user_id uuid references profiles(id)`
- `sizes jsonb`
- `preferred_colors text[]`
- `blocked_colors text[]`
- `preferred_brands text[]`
- `blocked_brands text[]`
- `price_min numeric`
- `price_max numeric`
- `preferred_store_ids uuid[]`
- `style_tags text[]`
- `fit_preferences text[]`
- `created_at timestamptz`
- `updated_at timestamptz`

RLS:
- Users can select, insert, update, and delete only their own preferences.

### `garments`
Catalog item.

Fields:
- `id uuid primary key`
- `brand text`
- `name text`
- `category text`
- `subcategory text`
- `color text`
- `style_tags text[]`
- `season_tags text[]`
- `size_system text`
- `available_sizes text[]`
- `price numeric`
- `currency text default 'AZN'`
- `image_url text`
- `source_url text`
- `metadata jsonb`
- `created_at timestamptz`
- `updated_at timestamptz`

RLS:
- Authenticated users can select catalog garments.
- Inserts and updates are service-role only through admin tools or ingestion functions.

### `stores`
Baku store or online source location.

Fields:
- `id uuid primary key`
- `name text`
- `brand text`
- `city text default 'Baku'`
- `address text`
- `source_id text unique`
- `source_type text`
- `source_config jsonb`
- `is_active boolean`
- `created_at timestamptz`
- `updated_at timestamptz`

RLS:
- Authenticated users can select active stores.
- Inserts and updates are service-role only.

### `stock_snapshots`
Point-in-time stock availability.

Fields:
- `id uuid primary key`
- `garment_id uuid references garments(id)`
- `store_id uuid references stores(id)`
- `size text`
- `stock_state text`
- `quantity integer null`
- `observed_at timestamptz`
- `source_id text`
- `source_url text`
- `confidence numeric`
- `raw_payload jsonb`

RLS:
- Authenticated users can select recent stock snapshots.
- Inserts are service-role only through ingestion functions.

### `events`
User-owned event.

Fields:
- `id uuid primary key`
- `user_id uuid references profiles(id)`
- `title text`
- `description text`
- `event_date date`
- `location_text text`
- `image_url text`
- `event_context jsonb`
- `created_at timestamptz`
- `updated_at timestamptz`

RLS:
- Users can manage only their own events.

### `outfit_recommendations`
Saved recommendation result for a user and event.

Fields:
- `id uuid primary key`
- `user_id uuid references profiles(id)`
- `event_id uuid references events(id)`
- `status text`
- `recommended_items jsonb`
- `score_breakdown jsonb`
- `reason_codes text[]`
- `stock_warnings text[]`
- `confidence numeric`
- `user_facing_explanation text`
- `model_version text`
- `created_at timestamptz`

RLS:
- Users can select only their own recommendations.
- Inserts are service-role only unless a future client-side draft mode is explicitly added.

### `recommendation_feedback`
User feedback for ranking improvement.

Fields:
- `id uuid primary key`
- `user_id uuid references profiles(id)`
- `recommendation_id uuid references outfit_recommendations(id)`
- `feedback_type text`
- `garment_id uuid null references garments(id)`
- `notes text`
- `created_at timestamptz`

RLS:
- Users can insert and select their own feedback.

## Edge Function Contracts
- `parse-event-context`: event text -> structured context.
- `generate-outfit-explanation`: ranked items + context -> safe user explanation.
- `score-recommendation-debug`: inputs -> deterministic score breakdown for development.
- `ingest-store-stock`: source id -> normalized stock snapshots.

## Migration Rules
- Create schema through migrations, not dashboard-only changes.
- Enable RLS in the same migration that creates each public table.
- Add indexes for `user_id`, `event_id`, `garment_id`, `store_id`, and `observed_at`.
- Run Supabase security and performance advisors after every schema migration.

