--   Retrieves a user's ID and password hash from their registration
-- number for authentication purposes.
SELECT
    u.id,
    u.password_hash,
    u.user_role
FROM public.user_account AS u
WHERE u.registration = $1;
