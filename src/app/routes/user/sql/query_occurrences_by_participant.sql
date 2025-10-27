-- 󰡦  Find all occurrences a user participated in
SELECT u.id
FROM public.user_account AS u
INNER JOIN public.brigade_membership AS bm
    ON u.id = bm.user_id
INNER JOIN public.occurrence_brigade AS ob
    ON bm.brigade_id = ob.brigade_id
WHERE ob.occurrence_id = $1;
