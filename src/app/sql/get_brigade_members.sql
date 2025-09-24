SELECT
    u.full_name,
    r.role_name,
    r.description
FROM public.user_account AS u
LEFT JOIN
    public.user_role AS r
    ON u.role_id = r.id
INNER JOIN
    public.query_brigade_members_id($1) AS brigade_members (id)
    ON u.id = brigade_members.id;
