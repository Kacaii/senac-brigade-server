--    Find all brigades an user is assigned to
select bm.brigade_id
from public.brigade_membership as bm
where bm.user_id = $1;
