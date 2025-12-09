-- 󰀖  Find user access level
select u.user_role
from
    public.user_account as u
where u.id = $1;
