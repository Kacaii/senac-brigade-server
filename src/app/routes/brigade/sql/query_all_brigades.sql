-- 󱉯  Find all registered brigades
SELECT
    b.id,
    b.brigade_name,
    u.full_name AS leader_name,
    b.is_active
FROM public.brigade AS b
LEFT JOIN public.user_account AS u
    ON b.leader_id = u.id;
