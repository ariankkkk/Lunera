with auth_profile_source as (
    select
        users.id,
        nullif(lower(trim(users.raw_user_meta_data ->> 'username')), '') as username,
        nullif(trim(users.raw_user_meta_data ->> 'display_name'), '') as display_name,
        users.created_at
    from auth.users
),
ranked_profiles as (
    select
        id,
        case
            when username is not null and row_number() over (partition by username order by created_at, id) = 1 then username
            else null
        end as safe_username,
        display_name,
        created_at
    from auth_profile_source
)
insert into public.profiles (id, username, display_name, created_at, updated_at)
select
    id,
    safe_username,
    coalesce(display_name, safe_username),
    coalesce(created_at, now()),
    now()
from ranked_profiles
on conflict (id) do nothing;
