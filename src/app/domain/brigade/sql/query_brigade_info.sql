-- 󰡦  Find details about a specific brigade
select
    b.id,
    b.brigade_name,
    u.id as leader_name,
    b.is_active
from public.brigade as b
inner join public.user_account as u
    on b.leader_id = u.id
where b.id = $1;
