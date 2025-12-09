--   Find all available user roles
select unnest(enum_range(null::public.user_role_enum)) as available_role;
