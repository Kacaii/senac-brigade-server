SELECT
    u.full_name,
    u.registration,
    r.role_name
FROM public.user_account AS u
LEFT JOIN public.user_role AS r
    ON r.id = u.role_id
WHERE u.id IN (
    SELECT *
    FROM public.get_brigade_members_id($1)
)
