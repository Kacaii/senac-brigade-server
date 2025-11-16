--   Register a new brigade into the database
INSERT INTO public.brigade AS b (
    leader_id,
    brigade_name,
    vehicle_code,
    is_active
) VALUES (
    $1,
    $2,
    $3,
    $4
) RETURNING
    b.id,
    b.created_at;
