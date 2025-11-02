--   Replace all assigned brigades
SELECT o.inserted_brigade_id
FROM public.assign_occurrence_brigades($1, $2) AS o;
