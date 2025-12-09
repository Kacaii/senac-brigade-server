create or replace view vw_count_active_occurrences as
select count(oc.id) as count
from public.occurrence as oc
where oc.resolved_at is null;

-----------------------------------------------------
create or replace view vw_count_recent_occurrences as
select count(oc.id) as count
from public.occurrence as oc
where oc.created_at >= (now() - '1 day'::interval);

----------------------------------------------------
create or replace view vw_count_total_occurrences as
select count(oc.id) as count
from public.occurrence as oc;

------------------------------------------------------
create or replace view vw_count_active_brigades as
select count(id)
from public.brigade
where is_active = true;
