--   Find the notification preferences for an user
SELECT
    np.notification_type,
    np.enabled
FROM public.notification_preference AS np
WHERE np.user_id = $1;
