-- 󰀖  Find all users that participated in a occurrence
SELECT p.id
FROM public.query_occurrence_participants($1) AS p;
