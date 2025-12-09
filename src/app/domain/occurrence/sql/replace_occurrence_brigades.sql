--   Replace all assigned brigades
select o.inserted_brigade_id
from public.assign_occurrence_brigades($1, $2) as o;
