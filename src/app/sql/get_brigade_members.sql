SELECT
    u.full_name,
    u.registration
FROM public.user_account AS u
INNER JOIN public.brigade_membership AS bm ON u.id = bm.user_id
WHERE bm.brigade_id = $1
