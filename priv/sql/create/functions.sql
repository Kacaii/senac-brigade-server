--   DROP -------------------------------------------------------------------
BEGIN;

DROP FUNCTION IF EXISTS public.query_user_id_by_registration;
DROP FUNCTION IF EXISTS public.query_brigade_members_id;
DROP FUNCTION IF EXISTS public.query_crew_members_id;
DROP FUNCTION IF EXISTS public.query_all_occurrences_by_user_id;

--   CREATE -------------------------------------------------------------------

--   Returns the user_account UUID by using their registration
CREATE OR REPLACE FUNCTION public.query_user_id_by_registration(rg TEXT)
RETURNS UUID AS $$

DECLARE user_id UUID;

BEGIN

SELECT u.id INTO user_id
  FROM public.user_account AS u
WHERE u.registration = $1;

RETURN user_id;

END;
$$ LANGUAGE plpgsql;

--   Returns all members of a brigade by using the brigade's UUID
CREATE OR REPLACE FUNCTION public.query_brigade_members_id(brigade_id UUID)
RETURNS SETOF UUID AS $$
BEGIN

RETURN QUERY

SELECT
    u.id
FROM public.user_account AS u
INNER JOIN public.brigade_membership AS bm ON u.id = bm.user_id
WHERE bm.brigade_id = $1;

END;
$$ LANGUAGE plpgsql;

--   Returns all users that are in the same brigades as the target user
CREATE OR REPLACE FUNCTION public.query_crew_members_id(user_id UUID)
RETURNS SETOF UUID AS $$
BEGIN

RETURN QUERY

SELECT u.id
FROM public.user_account AS u
INNER JOIN public.brigade_membership AS bm
    ON u.id = bm.user_id
INNER JOIN public.brigade AS b
    ON bm.brigade_id = b.id
WHERE bm.brigade_id IN (
    SELECT membership.brigade_id
    FROM brigade_membership AS membership
    WHERE membership.user_id = $1
) AND u.id != $1;

END;
$$ LANGUAGE plpgsql;
