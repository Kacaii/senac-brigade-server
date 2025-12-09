--   Retrieves a user's ID from their registration number.
select u.id
from public.user_account as u
where u.registration = $1;
