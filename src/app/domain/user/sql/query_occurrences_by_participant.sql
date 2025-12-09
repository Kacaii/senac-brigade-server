-- 󰡦  Find all occurrences a user participated in
select u.id
from public.user_account as u
inner join public.brigade_membership as bm
    on u.id = bm.user_id
inner join public.occurrence_brigade as ob
    on bm.brigade_id = ob.brigade_id
where ob.occurrence_id = $1;
