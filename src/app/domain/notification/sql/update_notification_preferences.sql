--   Update user notification preference
UPDATE public.user_notification_preference AS np
SET
    enabled = $3,
    updated_at = CURRENT_TIMESTAMP
WHERE
    np.user_id = $1
    AND np.notification_type = $2
RETURNING
    new.notification_type,
    new.enabled;
