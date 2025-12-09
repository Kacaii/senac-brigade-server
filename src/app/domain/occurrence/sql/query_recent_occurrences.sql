--   Find all occurrences from the last 24 hours
select
    o.id,
    o.created_at,
    o.description,
    o.occurrence_category,
    o.occurrence_subcategory,
    o.occurrence_location,
    o.reference_point
from public.occurrence as o
where o.created_at >= (now() - '1 day'::interval);
