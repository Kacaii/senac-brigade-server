BEGIN;

-- DROP ------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.query_crew_members;
DROP FUNCTION IF EXISTS public.assign_brigade_members;

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

COMMIT;
