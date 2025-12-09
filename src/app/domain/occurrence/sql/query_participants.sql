-- 󰀖  Find all users that participated in a occurrence
select distinct participant.user_id
from public.brigade_membership as participant
inner join public.occurrence_brigade as ob
    on participant.brigade_id = ob.brigade_id
where ob.occurrence_id = $1
order by participant.user_id;
