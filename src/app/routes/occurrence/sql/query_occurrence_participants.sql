-- 󰀖  Find all users that participated in a occurrence
SELECT p.user_id
FROM public.query_occurrence_participants($1) AS p;
