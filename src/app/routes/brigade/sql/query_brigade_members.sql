--   Find all members of a brigade
SELECT
    u.id,
    u.full_name,
    u.user_role
FROM public.user_account AS u
INNER JOIN public.brigade_membership AS bm
    ON u.id = bm.user_id
WHERE bm.brigade_id = $1;
