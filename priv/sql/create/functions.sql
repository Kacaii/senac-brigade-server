BEGIN;

-- DROP ------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.query_crew_members;
DROP FUNCTION IF EXISTS public.query_occurrence_participants;

-- CREATE ----------------------------------------------------------------------

--   Returns all users that are in the same brigades as the target user
CREATE OR REPLACE FUNCTION public.query_crew_members(user_id UUID)
RETURNS SETOF UUID
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT u.id
    FROM public.user_account AS u
    INNER JOIN public.brigade_membership AS bm ON u.id = bm.user_id
    INNER JOIN public.brigade AS b ON bm.brigade_id = b.id
    WHERE bm.brigade_id IN (
        SELECT membership.brigade_id
        FROM brigade_membership AS membership
        WHERE membership.user_id = $1
    ) AND u.id != $1;
END;
$$;

--   Return all users that participated in a occurrence
CREATE OR REPLACE FUNCTION public.query_occurrence_participants(occ_id UUID)
RETURNS SETOF UUID
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT u.id
    FROM public.user_account AS u
    INNER JOIN public.brigade_membership AS bm ON bm.user_id = u.id
    inner JOIN public.brigade AS b ON bm.brigade_id = b.id
    inner JOIN public.occurrence AS o ON b.id = ANY(o.brigade_list)
    where o.id = $1;
END;
$$;

COMMIT;
