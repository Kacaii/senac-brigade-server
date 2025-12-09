-- 󰚰  Mark a occurrence as resolved
update public.occurrence
set
    resolved_at = current_timestamp,
    updated_at = current_timestamp
where id = $1
returning
    id,
    resolved_at,
    updated_at;
