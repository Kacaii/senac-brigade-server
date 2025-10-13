-- 󰚰  Update an user `is_active` field
UPDATE public.user_account AS u
SET
    is_active = $2,
    updated_at = CURRENT_TIMESTAMP
WHERE u.id = $1
RETURNING u.id, u.is_active;
