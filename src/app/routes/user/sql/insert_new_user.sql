--   Inserts a new user into the database
INSERT INTO public.user_account AS u
(
    full_name,
    registration,
    phone,
    email,
    password_hash,
    user_role
)
VALUES ($1, $2, $3, $4, $5, $6)
RETURNING u.id;
