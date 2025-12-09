--   Retrieves a user's full name by their user ID.
select u.full_name
from public.user_account as u
where u.id = $1;
