-- 󰚰  Mark a occurrence as resolved
UPDATE public.occurrence
SET
    resolved_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP
WHERE id = $1
RETURNING
    id,
    resolved_at,
    updated_at;
