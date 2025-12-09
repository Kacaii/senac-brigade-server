--   Update user notification preference
update public.user_notification_preference as np
set
    enabled = $3,
    updated_at = current_timestamp
where
    np.user_id = $1
    and np.notification_type = $2
returning
    new.notification_type,
    new.enabled;
