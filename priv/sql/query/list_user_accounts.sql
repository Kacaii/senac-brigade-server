SELECT
    u.full_name,
    u.registration,
    u.phone,
    u.email
FROM public.user_account AS u
LIMIT 20;
