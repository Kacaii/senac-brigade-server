--   DROP -------------------------------------------------------------------
BEGIN;

DROP FUNCTION IF EXISTS public.get_user_id_by_registration;
DROP FUNCTION IF EXISTS public.get_category_id_by_name;
DROP FUNCTION IF EXISTS public.get_brigade_members_id;

--   CREATE -------------------------------------------------------------------

--   Returns the user_account UUID by using their registration ----------------
CREATE OR REPLACE FUNCTION public.get_user_id_by_registration(rg TEXT)
RETURNS UUID AS $$

DECLARE user_id UUID;

BEGIN

SELECT u.id INTO user_id
  FROM public.user_account AS u
WHERE u.registration = rg;

RETURN user_id;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.get_category_id_by_name(input_name TEXT)
RETURNS UUID AS $$

DECLARE category_id UUID;

BEGIN

SELECT oc.id INTO category_id
FROM public.occurrence_category AS oc
WHERE oc.category_name = input_name;

RETURN category_id;

END;
$$ LANGUAGE plpgsql;

--   Returns all members of a brigade by using the brigade's UUID -------------
CREATE OR REPLACE FUNCTION public.get_brigade_members_id(brigade_id UUID)
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


-- TODO: Maybe something similar to the file bellow:
-- >       src/app/sql/get_brigade_members.sql
-- Also, this should be a SELECT statement somewhere in src/app/sql
-- 
CREATE OR REPLACE FUNCTION public.get_fellow_brigade_members_id(user_id UUID)
RETURNS SETOF UUID AS $$
BEGIN

RETURN QUERY
SELECT
    u.id AS user_id,
    b.id AS brigade_id,
    b.brigade_name
FROM public.user_account AS u
INNER JOIN public.brigade_membership AS bm
    ON u.id = bm.user_id
INNER JOIN public.brigade AS b
    ON b.id = bm.brigade_id
WHERE bm.brigade_id IN (
    SELECT bm.brigade_id
    FROM brigade_membership AS bm
    WHERE bm.user_id = $1
);

END;
$$ LANGUAGE plpgsql;

COMMIT;
