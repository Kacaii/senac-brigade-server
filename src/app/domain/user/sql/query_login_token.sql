--   Retrieves a user's ID and password hash from their registration
-- number for authentication purposes.
select
    u.id,
    u.password_hash,
    u.user_role
from public.user_account as u
where u.registration = $1;
