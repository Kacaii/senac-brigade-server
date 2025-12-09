--   Assign a list of members to a brigade
select b.inserted_user_id
from public.assign_brigade_members($1, $2) as b;
