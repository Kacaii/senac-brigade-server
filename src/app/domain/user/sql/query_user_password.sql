--   Find the password hash from an user
SELECT u.password_hash
FROM public.user_account AS u
WHERE u.id = $1;
