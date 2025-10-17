-- 󰀖  Find all users that participated in a occurrence
SELECT u.id
FROM public.occurrence_brigade_member AS obm
INNER JOIN public.user_account AS u
    ON obm.user_id = u.id
INNER JOIN public.occurrence AS o
    ON obm.occurrence_id = o.id
WHERE obm.occurrence_id = $1;
