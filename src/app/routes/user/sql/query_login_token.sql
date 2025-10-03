--   Retrieves a user's ID and password hash from their registration
-- number for authentication purposes.
SELECT
    u.id,
    u.password_hash
FROM public.user_account AS u
WHERE u.registration = $1;
