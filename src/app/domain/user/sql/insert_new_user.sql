--   Inserts a new user into the database
insert into public.user_account as u
(
    full_name,
    registration,
    phone,
    email,
    password_hash,
    user_role
)
values ($1, $2, $3, $4, $5, $6)
returning u.id;
