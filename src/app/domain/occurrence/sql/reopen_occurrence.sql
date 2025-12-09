-- 󰚰  Mark a occurrence as unresolved
update public.occurrence
set
    resolved_at = null,
    updated_at = current_timestamp
where id = $1
returning
    id,
    resolved_at,
    updated_at;
