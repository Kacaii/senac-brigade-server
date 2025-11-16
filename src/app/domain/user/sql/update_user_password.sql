--   Set an new value to the password of an user
UPDATE public.user_account
SET
    password_hash = $2,
    updated_at = CURRENT_TIMESTAMP
WHERE id = $1;
