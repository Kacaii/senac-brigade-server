BEGIN;

-- DROP ------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.query_crew_members;
DROP FUNCTION IF EXISTS public.query_occurrence_participants;

-- CREATE ----------------------------------------------------------------------

--   Returns all users that are in the same brigades as the target user
CREATE OR REPLACE FUNCTION public.query_crew_members(p_user_id UUID)
RETURNS TABLE (member_id UUID)
LANGUAGE plpgsql
STABLE
PARALLEL SAFE
AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT u.id
    FROM public.user_account AS u
    INNER JOIN public.brigade_membership AS bm ON u.id = bm.user_id
    INNER JOIN public.brigade AS b ON bm.brigade_id = b.id
    INNER JOIN public.brigade_membership AS target_bm
        ON bm.brigade_id = target_bm.brigade_id
    WHERE target_bm.user_id = p_user_id
        AND u.id <> p_user_id;
END;
$$;

--   Return all users that participated in a occurrence
CREATE OR REPLACE FUNCTION public.query_occurrence_participants(p_occ_id UUID)
RETURNS TABLE (id UUID)
LANGUAGE plpgsql
STABLE
PARALLEL SAFE
AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT u.id
    FROM public.occurrence AS occ
    INNER JOIN public.brigade AS b ON b.id = ANY(occ.brigade_list)
    INNER JOIN public.user_account as u on u.id = ANY(b.members_id)
    WHERE occ.id = p_occ_id;
END;
$$;

COMMIT;
