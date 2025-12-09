--   Register a new brigade into the database
insert into public.brigade as b (
    leader_id,
    brigade_name,
    vehicle_code,
    is_active
) values (
    $1,
    $2,
    $3,
    $4
) returning
    b.id,
    b.created_at;
