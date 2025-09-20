SELECT u.password_hash
FROM public.user_account AS u
WHERE u.registration = $1;
