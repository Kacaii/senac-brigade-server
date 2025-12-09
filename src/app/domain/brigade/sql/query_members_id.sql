--   Find the id of all members assigned a specific brigade
select u.id
from public.user_account as u
inner join public.brigade_membership as bm
    on u.id = bm.user_id
where bm.brigade_id = $1;
