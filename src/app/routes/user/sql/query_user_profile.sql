SELECT
    u.id,
    u.full_name,
    u.registration,
    r.role_name,
    u.email,
    u.phone
FROM
    public.user_account AS u
LEFT JOIN public.user_role AS r
    ON u.role_id = r.id
WHERE u.id = $1;
