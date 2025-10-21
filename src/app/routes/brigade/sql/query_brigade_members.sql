--   Find all members of a brigade
SELECT
    u.id,
    u.full_name,
    u.user_role
FROM public.user_account AS u
INNER JOIN
    public.brigade AS b
    ON u.id = ANY(b.members_id)
WHERE b.id = $1;
