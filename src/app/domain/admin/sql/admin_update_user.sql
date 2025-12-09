--   Update an user's information as admin
update public.user_account as u
set
    full_name = $2,
    email = $3,
    user_role = $4,
    registration = $5,
    is_active = $6,
    updated_at = current_timestamp
where u.id = $1
returning
    u.id,
    u.full_name,
    u.email,
    u.user_role,
    u.registration,
    u.is_active,
    u.updated_at;
