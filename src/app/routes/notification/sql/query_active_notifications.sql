--   Find the active notifications from an user
SELECT np.notification_type
FROM public.user_notification_preference AS np
WHERE
    np.user_id = $1
    AND np.enabled = TRUE;
