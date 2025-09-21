SELECT
    u.full_name,
    u.registration,
    r.role_name
FROM public.user_account AS u
LEFT JOIN public.user_role AS r ON r.id = u.role_id
INNER JOIN public.get_brigade_members_id($1) AS brigade_members (id)
    ON brigade_members.id = u.id;
