-- 󱉯  Find all registered brigades
select
    b.id,
    b.brigade_name,
    u.full_name as leader_name,
    b.is_active
from public.brigade as b
left join public.user_account as u
    on b.leader_id = u.id;
