SELECT
    u.full_name,
    r.role_name,
    r.description
FROM QUERY_FELLOW_BRIGADE_MEMBERS_ID($1) AS fellow_members (id)
INNER JOIN
    public.user_account AS u
    ON fellow_members.id = u.id
LEFT JOIN
    public.user_role AS r
    ON u.role_id = r.id;
