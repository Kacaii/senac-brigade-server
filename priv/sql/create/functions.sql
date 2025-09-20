--   DROP -------------------------------------------------------------------
BEGIN;

DROP FUNCTION IF EXISTS public.get_user_id_by_registration;
DROP FUNCTION IF EXISTS public.get_category_id_by_name;

--   CREATE -----------------------------------------------------------------

--   In case we need the database ID
CREATE OR REPLACE FUNCTION public.get_user_id_by_registration(registration TEXT)
RETURNS UUID AS $$

DECLARE user_id UUID;

BEGIN

SELECT u.id INTO user_id
  FROM public.user_account AS u
WHERE u.registration = $1;

RETURN user_id;

END;
$$ LANGUAGE plpgsql;

--   In case we only know the name.
CREATE OR REPLACE FUNCTION public.get_category_id_by_name(name TEXT)
RETURNS UUID AS $$

DECLARE category_id UUID;

BEGIN

SELECT oc.id INTO category_id
FROM public.occurrence_category AS oc
WHERE oc.category_name = $1;

RETURN category_id;

END;
$$ LANGUAGE plpgsql;

COMMIT;
