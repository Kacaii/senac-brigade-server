--   Retrieves all occurrences associated with a user,
-- including detailed category information and resolution status.
SELECT
    o.id,
    o.description,
    o.occurrence_category,
    o.occurrence_subcategory,
    o.created_at,
    o.updated_at,
    o.resolved_at,
    o.location,
    o.reference_point
FROM public.query_all_occurrences_by_user_id($1) AS oc_list (id)
INNER JOIN public.occurrence AS o
    ON oc_list.id = o.id
