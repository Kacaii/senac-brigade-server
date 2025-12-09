--   Remove and user from the database
delete from public.user_account as u
where u.id = $1
returning u.id, u.full_name;
