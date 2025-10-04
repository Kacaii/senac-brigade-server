--   Update user notification preference
UPDATE public.notification_preference AS np
SET
    enabled = $3,
    updated_at = CURRENT_TIMESTAMP
WHERE
    np.user_id = $1
    AND np.notification_type = $2;
