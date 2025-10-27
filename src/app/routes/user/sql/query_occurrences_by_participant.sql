-- 󰡦  Find all occurrences a user participated in
SELECT o.id
FROM public.occurrence_participant AS op
INNER JOIN public.user_account AS u
    ON op.user_id = u.id
INNER JOIN public.occurrence AS o
    ON op.occurrence_id = o.id
WHERE op.user_id = $1;
