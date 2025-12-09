--   Find the notification preferences for an user
select
    np.notification_type,
    np.enabled
from public.user_notification_preference as np
where np.user_id = $1;
