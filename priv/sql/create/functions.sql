BEGIN;

-- DROP ------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.query_crew_members;
DROP FUNCTION IF EXISTS public.assign_brigade_members;
DROP FUNCTION IF EXISTS public.replace_brigade_members;
DROP FUNCTION IF EXISTS public.assign_occurrence_brigades;
DROP FUNCTION IF EXISTS public.replace_occurrence_brigades;

-- CREATE ----------------------------------------------------------------------

--   Returns all users that are in the same brigades as the target user
CREATE OR REPLACE FUNCTION public.query_crew_members(p_user_id UUID)
RETURNS TABLE (member_id UUID, brigade_id UUID)
LANGUAGE plpgsql
STABLE
PARALLEL SAFE
AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT bm.user_id as member_id, bm.brigade_id as brigade_id
    FROM public.brigade_membership AS bm
    INNER JOIN public.brigade_membership AS target_bm
        ON bm.brigade_id = target_bm.brigade_id
    WHERE target_bm.user_id = p_user_id
        AND bm.user_id <> p_user_id;
END;
$$;

-- 󰮆  Assign members to a brigade
CREATE OR REPLACE FUNCTION public.assign_brigade_members(
    p_brigade_id UUID,
    p_members_id UUID []
)
RETURNS TABLE (inserted_user_id UUID)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    INSERT INTO public.brigade_membership AS bm
        (brigade_id, user_id)
    SELECT
        p_brigade_id,
        member_id
    FROM unnest(p_members_id) as member_id
    ON CONFLICT (brigade_id, user_id)
    DO NOTHING
    RETURNING user_id;
END;
$$;


-- 󰮆  Replace assigned members from a brigade
CREATE OR REPLACE FUNCTION public.replace_brigade_members(
    p_brigade_id UUID,
    p_members_id UUID []
)
RETURNS TABLE (inserted_user_id UUID)
LANGUAGE plpgsql
AS $$
BEGIN
    --   Remove all current members
    DELETE FROM public.brigade_membership AS bm
    WHERE bm.brigade_id = p_brigade_id;

    --  Assign the new ones
    RETURN QUERY
    SELECT b.inserted_user_id
    FROM public.assign_brigade_members(p_brigade_id, p_members_id) AS b;
END;
$$;


-- 󰮆  Assign brigades to a occurrence
CREATE OR REPLACE FUNCTION public.assign_occurrence_brigades(
    p_occurrence_id UUID,
    p_brigades_id UUID []
)
RETURNS TABLE (inserted_brigade_id UUID)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    INSERT INTO public.occurrence_brigade AS oc
        (occurrence_id, brigade_id)
    SELECT
        p_occurrence_id,
        brigade_id
    FROM unnest(p_brigades_id) as brigade_id
    ON CONFLICT (occurrence_id, brigade_id)
    DO NOTHING
    RETURNING brigade_id;
END;
$$;


-- 󰮆  Replace assigned brigades from a occurrence
CREATE OR REPLACE FUNCTION public.replace_occurrence_brigades(
    p_occurrence_id UUID,
    p_brigades_id UUID []
)
RETURNS TABLE (inserted_brigade_id UUID)
LANGUAGE plpgsql
AS $$
BEGIN
    --    Remove all current assigned brigades
    DELETE FROM public.occurrence_brigade AS ob
    WHERE ob.occurrence_id = p_occurrence_id;

    --    Assign the new ones
    RETURN QUERY
    SELECT o.inserted_brigade_id
    FROM public.assign_occurrence_brigades(p_occurrence_id, p_brigades_id) AS o;
END;
$$;

COMMIT;
