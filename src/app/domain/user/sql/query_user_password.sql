--   Find the password hash from an user
select u.password_hash
from public.user_account as u
where u.id = $1;
