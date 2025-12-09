begin;

-- DROP ------------------------------------------------------------------------
drop function if exists public.query_crew_members;
drop function if exists public.assign_brigade_members;
drop function if exists public.replace_brigade_members;
drop function if exists public.assign_occurrence_brigades;
drop function if exists public.replace_occurrence_brigades;

-- CREATE ----------------------------------------------------------------------

--   Returns all users that are in the same brigades as the target user
create or replace function public.query_crew_members(p_user_id uuid)
returns table (member_id uuid, brigade_id uuid)
language plpgsql
stable
parallel safe
as $$
begin
    return query
    select distinct bm.user_id as member_id, bm.brigade_id as brigade_id
    from public.brigade_membership as bm
    inner join public.brigade_membership as target_bm
        on bm.brigade_id = target_bm.brigade_id
    where target_bm.user_id = p_user_id
        and bm.user_id <> p_user_id;
end;
$$;

-- 󰮆  Assign members to a brigade
create or replace function public.assign_brigade_members(
    p_brigade_id uuid,
    p_members_id uuid []
)
returns table (inserted_user_id uuid)
language plpgsql
as $$
begin
    return query
    insert into public.brigade_membership as bm
        (brigade_id, user_id)
    select
        p_brigade_id,
        member_id
    from unnest(p_members_id) as member_id
    on conflict (brigade_id, user_id)
    do nothing
    returning user_id;
end;
$$;


-- 󰮆  Replace assigned members from a brigade
create or replace function public.replace_brigade_members(
    p_brigade_id uuid,
    p_members_id uuid []
)
returns table (inserted_user_id uuid)
language plpgsql
as $$
begin
    --   Remove all current members
    delete from public.brigade_membership as bm
    where bm.brigade_id = p_brigade_id;

    --   Assign the new ones
    return query
    select b.inserted_user_id
    from public.assign_brigade_members(p_brigade_id, p_members_id) as b;
end;
$$;


-- 󰮆  Assign brigades to a occurrence
create or replace function public.assign_occurrence_brigades(
    p_occurrence_id uuid,
    p_brigades_id uuid []
)
returns table (inserted_brigade_id uuid)
language plpgsql
as $$
begin
    return query
    insert into public.occurrence_brigade as oc
        (occurrence_id, brigade_id)
    select
        p_occurrence_id,
        brigade_id
    from unnest(p_brigades_id) as brigade_id
    on conflict (occurrence_id, brigade_id)
    do nothing
    returning brigade_id;
end;
$$;


-- 󰮆  replace assigned brigades from a occurrence
create or replace function public.replace_occurrence_brigades(
    p_occurrence_id uuid,
    p_brigades_id uuid []
)
returns table (inserted_brigade_id uuid)
language plpgsql
as $$
begin
    --   Remove all current assigned brigades
    delete from public.occurrence_brigade as ob
    where ob.occurrence_id = p_occurrence_id;

    --   Assign the new ones
    return query
    select o.inserted_brigade_id
    from public.assign_occurrence_brigades(p_occurrence_id, p_brigades_id) as o;
end;
$$;

commit;
