SELECT u.id
FROM public.user_account AS u
WHERE u.registration = $1;
