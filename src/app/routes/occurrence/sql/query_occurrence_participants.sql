-- 󰀖  Find all users that participated in a occurrence
SELECT DISTINCT participant.user_id
FROM public.brigade_membership AS participant
INNER JOIN public.occurrence_brigade AS ob
    ON participant.brigade_id = ob.brigade_id
WHERE ob.occurrence_id = $1;
