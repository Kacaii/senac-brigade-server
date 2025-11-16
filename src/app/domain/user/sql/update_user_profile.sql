--   Update an authenticated user profile
UPDATE public.user_account AS u SET
    full_name = $2,
    email = $3,
    phone = $4
WHERE u.id = $1
RETURNING
    u.full_name,
    u.email,
    u.phone;
