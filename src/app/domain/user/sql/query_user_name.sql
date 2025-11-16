--   Retrieves a user's full name by their user ID.
SELECT u.full_name
FROM public.user_account AS u
WHERE u.id = $1;
