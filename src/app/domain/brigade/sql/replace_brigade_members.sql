--   Replace all brigade members
select b.inserted_user_id
from public.replace_brigade_members($1, $2) as b;
