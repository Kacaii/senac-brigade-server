--   Find the active notifications from an user
select np.notification_type
from public.user_notification_preference as np
where
    np.user_id = $1
    and np.enabled = true;
