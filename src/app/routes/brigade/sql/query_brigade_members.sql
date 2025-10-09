--   Find all members of a brigade
SELECT
    u.id,
    u.full_name,
    u.user_role
FROM public.user_account AS u
INNER JOIN
    public.query_brigade_members_id($1) AS brigade_members (id)
    ON u.id = brigade_members.id;
