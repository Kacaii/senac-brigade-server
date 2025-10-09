--   Find all available user roles
SELECT UNNEST(ENUM_RANGE(NULL::public.USER_ROLE_ENUM)) AS available_role;
