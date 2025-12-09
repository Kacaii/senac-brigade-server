--    Assign as list of brigades as participants of a occurrence
select ob.inserted_brigade_id
from public.assign_occurrence_brigades($1, $2) as ob;
