--   Find all occurrences from the last 24 hours
SELECT
    o.id,
    o.created_at,
    o.description,
    o.occurrence_category,
    o.occurrence_subcategory,
    o.location,
    o.reference_point
FROM public.occurrence AS o
WHERE o.created_at >= (NOW() - '1 day'::INTERVAL);
