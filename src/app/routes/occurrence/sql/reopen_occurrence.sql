-- 󰚰  Mark a occurrence as unresolved
UPDATE public.occurrence
SET
    resolved_at = NULL,
    updated_at = CURRENT_TIMESTAMP
WHERE id = $1
RETURNING
    id,
    resolved_at,
    updated_at;
