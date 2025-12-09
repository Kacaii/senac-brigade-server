--   Set the brigade is_active status to ON or OFF
update public.brigade as b
set
    is_active = $2,
    updated_at = current_timestamp
where b.id = $1
returning
    b.id,
    b.is_active,
    b.updated_at;
