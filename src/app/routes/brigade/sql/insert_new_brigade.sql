--   Register a new brigade into the database
INSERT INTO public.brigade AS b (
    leader_id,
    brigade_name,
    vehicle_code,
    members_id,
    is_active
) VALUES (
    $1,
    $2,
    $3,
    $4,
    $5
) RETURNING
    b.id,
    b.created_at;
