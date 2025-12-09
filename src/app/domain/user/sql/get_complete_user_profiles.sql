-- 󰀖  Find all users on the database
select
    u.id,
    u.full_name,
    u.registration,
    u.email,
    u.user_role,
    u.is_active
from public.user_account as u;
