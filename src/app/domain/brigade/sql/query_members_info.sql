--   Find all members of a brigade
select
    u.id,
    u.full_name,
    u.user_role
from public.user_account as u
inner join public.brigade_membership as bm
    on u.id = bm.user_id
where bm.brigade_id = $1;
