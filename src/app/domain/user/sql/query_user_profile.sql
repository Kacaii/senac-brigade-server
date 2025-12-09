-- 󰀖  Find basic information about an user account
select
    u.id,
    u.full_name,
    u.registration,
    u.user_role,
    u.email,
    u.phone
from public.user_account as u
where u.id = $1;
