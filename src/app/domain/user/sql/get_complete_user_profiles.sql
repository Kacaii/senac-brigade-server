-- 󰀖  Find all users on the database
SELECT
    u.id,
    u.full_name,
    u.registration,
    u.email,
    u.user_role,
    u.is_active
FROM public.user_account AS u;
