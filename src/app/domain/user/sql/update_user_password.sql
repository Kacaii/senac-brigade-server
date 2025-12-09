--   Set an new value to the password of an user
update public.user_account
set
    password_hash = $2,
    updated_at = current_timestamp
where id = $1;
