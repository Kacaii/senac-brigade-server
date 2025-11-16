--   Update an user's information as admin
UPDATE public.user_account AS u
SET
    full_name = $2,
    email = $3,
    user_role = $4,
    registration = $5,
    is_active = $6,
    updated_at = CURRENT_TIMESTAMP
WHERE u.id = $1
RETURNING
    u.id,
    u.full_name,
    u.email,
    u.user_role,
    u.registration,
    u.is_active,
    u.updated_at;
