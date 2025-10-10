--   Set the brigade is_active status to ON or OFF
UPDATE public.brigade AS b
SET
    is_active = $2,
    updated_at = CURRENT_TIMESTAMP
WHERE b.id = $1
RETURNING
    b.id,
    b.is_active,
    b.updated_at;
