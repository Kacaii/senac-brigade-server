-- 󰡦  Find details about a specific brigade
SELECT
    b.id,
    b.brigade_name,
    u.id AS leader_name,
    b.is_active
FROM public.brigade AS b
INNER JOIN public.user_account AS u
    ON b.leader_id = u.id
WHERE b.id = $1;
