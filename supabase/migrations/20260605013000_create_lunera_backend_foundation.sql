create schema if not exists private;

revoke all on schema private from public;
grant usage on schema private to postgres, service_role;

create table public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    username text unique,
    display_name text,
    avatar_url text,
    home_city text not null default 'Baku',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint profiles_username_format check (username is null or username ~ '^[a-z0-9._]{3,24}$')
);

create table public.user_preferences (
    id uuid primary key default extensions.gen_random_uuid(),
    user_id uuid not null references public.profiles(id) on delete cascade,
    sizes jsonb not null default '{}'::jsonb,
    preferred_colors text[] not null default '{}',
    blocked_colors text[] not null default '{}',
    preferred_brands text[] not null default '{}',
    blocked_brands text[] not null default '{}',
    price_min numeric(10, 2),
    price_max numeric(10, 2),
    preferred_store_ids uuid[] not null default '{}',
    style_tags text[] not null default '{}',
    fit_preferences text[] not null default '{}',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint user_preferences_price_range check (
        (price_min is null or price_min >= 0)
        and (price_max is null or price_max >= 0)
        and (price_min is null or price_max is null or price_min <= price_max)
    )
);

create unique index user_preferences_user_id_key on public.user_preferences(user_id);

create table public.garments (
    id uuid primary key default extensions.gen_random_uuid(),
    brand text,
    name text not null,
    category text not null,
    subcategory text,
    color text,
    style_tags text[] not null default '{}',
    season_tags text[] not null default '{}',
    size_system text,
    available_sizes text[] not null default '{}',
    price numeric(10, 2),
    currency text not null default 'AZN',
    image_url text,
    source_url text,
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint garments_price_nonnegative check (price is null or price >= 0)
);

create table public.stores (
    id uuid primary key default extensions.gen_random_uuid(),
    name text not null,
    brand text,
    city text not null default 'Baku',
    address text,
    source_id text unique,
    source_type text not null default 'manual',
    source_config jsonb not null default '{}'::jsonb,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint stores_source_type_check check (source_type in ('website', 'api', 'manual', 'marketplace'))
);

create table public.stock_snapshots (
    id uuid primary key default extensions.gen_random_uuid(),
    garment_id uuid not null references public.garments(id) on delete cascade,
    store_id uuid not null references public.stores(id) on delete cascade,
    size text not null,
    stock_state text not null default 'unknown',
    quantity integer,
    observed_at timestamptz not null default now(),
    source_id text,
    source_url text,
    confidence numeric(4, 3),
    raw_payload jsonb not null default '{}'::jsonb,
    constraint stock_snapshots_state_check check (stock_state in ('in_stock', 'low_stock', 'out_of_stock', 'unknown')),
    constraint stock_snapshots_quantity_nonnegative check (quantity is null or quantity >= 0),
    constraint stock_snapshots_confidence_range check (confidence is null or (confidence >= 0 and confidence <= 1))
);

create table public.events (
    id uuid primary key default extensions.gen_random_uuid(),
    user_id uuid not null references public.profiles(id) on delete cascade,
    title text not null,
    description text,
    event_date date,
    location_text text,
    image_url text,
    event_context jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table public.outfit_recommendations (
    id uuid primary key default extensions.gen_random_uuid(),
    user_id uuid not null references public.profiles(id) on delete cascade,
    event_id uuid references public.events(id) on delete set null,
    status text not null default 'generated',
    recommended_items jsonb not null default '[]'::jsonb,
    score_breakdown jsonb not null default '{}'::jsonb,
    reason_codes text[] not null default '{}',
    stock_warnings text[] not null default '{}',
    confidence numeric(4, 3),
    user_facing_explanation text,
    model_version text,
    created_at timestamptz not null default now(),
    constraint outfit_recommendations_status_check check (status in ('draft', 'generated', 'shown', 'saved', 'dismissed', 'failed')),
    constraint outfit_recommendations_confidence_range check (confidence is null or (confidence >= 0 and confidence <= 1))
);

create table public.recommendation_feedback (
    id uuid primary key default extensions.gen_random_uuid(),
    user_id uuid not null references public.profiles(id) on delete cascade,
    recommendation_id uuid not null references public.outfit_recommendations(id) on delete cascade,
    feedback_type text not null,
    garment_id uuid references public.garments(id) on delete set null,
    notes text,
    created_at timestamptz not null default now(),
    constraint recommendation_feedback_type_check check (feedback_type in ('like', 'dislike', 'hide_item', 'chosen', 'notes'))
);

create index user_preferences_user_id_idx on public.user_preferences(user_id);
create index garments_category_idx on public.garments(category);
create index stores_active_city_idx on public.stores(is_active, city);
create index stock_snapshots_garment_id_idx on public.stock_snapshots(garment_id);
create index stock_snapshots_store_id_idx on public.stock_snapshots(store_id);
create index stock_snapshots_observed_at_idx on public.stock_snapshots(observed_at desc);
create index events_user_id_idx on public.events(user_id);
create index outfit_recommendations_user_id_idx on public.outfit_recommendations(user_id);
create index outfit_recommendations_event_id_idx on public.outfit_recommendations(event_id);
create index recommendation_feedback_user_id_idx on public.recommendation_feedback(user_id);
create index recommendation_feedback_recommendation_id_idx on public.recommendation_feedback(recommendation_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

revoke all on function public.set_updated_at() from public;

create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger set_user_preferences_updated_at
before update on public.user_preferences
for each row execute function public.set_updated_at();

create trigger set_garments_updated_at
before update on public.garments
for each row execute function public.set_updated_at();

create trigger set_stores_updated_at
before update on public.stores
for each row execute function public.set_updated_at();

create trigger set_events_updated_at
before update on public.events
for each row execute function public.set_updated_at();

create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    profile_username text;
    profile_display_name text;
begin
    profile_username := nullif(lower(trim(new.raw_user_meta_data ->> 'username')), '');
    profile_display_name := nullif(trim(new.raw_user_meta_data ->> 'display_name'), '');

    insert into public.profiles (id, username, display_name)
    values (
        new.id,
        profile_username,
        coalesce(profile_display_name, profile_username)
    )
    on conflict (id) do update
    set
        username = coalesce(public.profiles.username, excluded.username),
        display_name = coalesce(public.profiles.display_name, excluded.display_name),
        updated_at = now();

    return new;
end;
$$;

revoke all on function private.handle_new_user() from public;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function private.handle_new_user();

alter table public.profiles enable row level security;
alter table public.user_preferences enable row level security;
alter table public.garments enable row level security;
alter table public.stores enable row level security;
alter table public.stock_snapshots enable row level security;
alter table public.events enable row level security;
alter table public.outfit_recommendations enable row level security;
alter table public.recommendation_feedback enable row level security;

create policy "Users can select own profile"
on public.profiles for select
to authenticated
using ((select auth.uid()) = id);

create policy "Users can insert own profile"
on public.profiles for insert
to authenticated
with check ((select auth.uid()) = id);

create policy "Users can update own profile"
on public.profiles for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

create policy "Users can select own preferences"
on public.user_preferences for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "Users can insert own preferences"
on public.user_preferences for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy "Users can update own preferences"
on public.user_preferences for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "Users can delete own preferences"
on public.user_preferences for delete
to authenticated
using ((select auth.uid()) = user_id);

create policy "Authenticated users can select garments"
on public.garments for select
to authenticated
using (true);

create policy "Authenticated users can select active stores"
on public.stores for select
to authenticated
using (is_active);

create policy "Authenticated users can select recent stock"
on public.stock_snapshots for select
to authenticated
using (observed_at >= now() - interval '30 days');

create policy "Users can select own events"
on public.events for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "Users can insert own events"
on public.events for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy "Users can update own events"
on public.events for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "Users can delete own events"
on public.events for delete
to authenticated
using ((select auth.uid()) = user_id);

create policy "Users can select own outfit recommendations"
on public.outfit_recommendations for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "Users can select own recommendation feedback"
on public.recommendation_feedback for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "Users can insert own recommendation feedback"
on public.recommendation_feedback for insert
to authenticated
with check ((select auth.uid()) = user_id);

grant usage on schema public to authenticated, service_role;
grant select, insert, update on public.profiles to authenticated;
grant select, insert, update, delete on public.user_preferences to authenticated;
grant select on public.garments to authenticated;
grant select on public.stores to authenticated;
grant select on public.stock_snapshots to authenticated;
grant select, insert, update, delete on public.events to authenticated;
grant select on public.outfit_recommendations to authenticated;
grant select, insert on public.recommendation_feedback to authenticated;

grant all on all tables in schema public to service_role;
grant execute on function public.set_updated_at() to service_role;
