--   Update an authenticated user profile
update public.user_account as u set
    full_name = $2,
    email = $3,
    phone = $4
where u.id = $1
returning
    u.full_name,
    u.email,
    u.phone;
