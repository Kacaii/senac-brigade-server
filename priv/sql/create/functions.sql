BEGIN;

-- DROP ------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.query_crew_members;
DROP FUNCTION IF EXISTS public.query_occurrence_participants;

-- CREATE ----------------------------------------------------------------------

--   Returns all users that are in the same brigades as the target user
CREATE OR REPLACE FUNCTION public.query_crew_members(p_user_uuid UUID)
RETURNS TABLE (member_uuid UUID, brigade_uuid UUID)
LANGUAGE plpgsql
STABLE
PARALLEL SAFE
AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT bm.user_id as member_uuid, bm.brigade_id as brigade_uuid
    FROM public.brigade_membership AS bm
    INNER JOIN public.brigade_membership AS target_bm
        ON bm.brigade_id = target_bm.brigade_id
    WHERE target_bm.user_id = p_user_uuid
        AND bm.user_id <> p_user_uuid;
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
