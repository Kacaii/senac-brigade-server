--    Assign a brigade as participant of a occurrence
INSERT INTO public.occurrence_brigade AS ob
(occurrence_id, brigade_id)
VALUES
($1, $2)
ON CONFLICT
(occurrence_id, brigade_id)
DO NOTHING
RETURNING brigade_id;
