--    Find all brigades an user is assigned to
SELECT bm.brigade_id
FROM public.brigade_membership AS bm
WHERE bm.user_id = $1;
