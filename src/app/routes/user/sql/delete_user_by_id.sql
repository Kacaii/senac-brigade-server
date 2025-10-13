--   Remove and user from the database
DELETE FROM public.user_account AS u
WHERE u.id = $1
RETURNING u.id, u.full_name;
