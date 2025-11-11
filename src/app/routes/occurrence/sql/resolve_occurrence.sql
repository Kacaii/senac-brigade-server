-- 󰚰  Resolve a occurrence
UPDATE public.occurrence
SET resolved_at = CURRENT_TIMESTAMP
WHERE id = $1
RETURNING
    id,
    resolved_at;
