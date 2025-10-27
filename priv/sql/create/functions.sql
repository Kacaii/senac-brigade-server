BEGIN;

-- DROP ------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.query_crew_members;

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

COMMIT;
