-- 󰀖  Find basic information about an user account
SELECT
    u.id,
    u.full_name,
    u.registration,
    u.user_role,
    u.email,
    u.phone
FROM public.user_account AS u
WHERE u.id = $1;
