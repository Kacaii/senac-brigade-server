--    Assign as list of brigades as participants of a occurrence
SELECT ob.inserted_brigade_id
FROM public.assign_occurrence_brigades($1, $2) AS ob;
