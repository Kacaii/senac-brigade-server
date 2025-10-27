--    Assign a brigade as participant of a occurrence
INSERT INTO public.occurrence_brigade AS ob
(occurrence_id, brigade_id)
VALUES
(
    $1,
    $2
) RETURNING brigade_id;
