-- 󰢫  Retrieves detailed information about fellow brigade members
-- for a given user, including their names and role details.
select
    u.id,
    u.full_name,
    u.user_role,
    crew.brigade_id
from public.query_crew_members($1) as crew
inner join public.user_account as u
    on crew.member_id = u.id;
