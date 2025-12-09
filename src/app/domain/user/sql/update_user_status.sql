-- 󰚰  Update an user `is_active` field
update public.user_account as u
set
    is_active = $2,
    updated_at = current_timestamp
where u.id = $1
returning u.id, u.is_active;
