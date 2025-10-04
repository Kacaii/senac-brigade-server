--   Retrieves all occurrences associated with a user,
-- including detailed category information and resolution status.
SELECT
    o.id,
    o.description,
    oc_cat.category_name AS category,
    sub_cat.category_name AS subcategory,
    o.created_at,
    o.updated_at,
    o.resolved_at,
    o.location,
    o.reference_point
FROM public.query_all_ocurrences_by_user_id($1) AS oc_list (id)
INNER JOIN public.occurrence AS o
    ON oc_list.id = o.id
LEFT JOIN public.occurrence_category AS oc_cat
    ON o.category_id = oc_cat.id
LEFT JOIN public.occurrence_category AS sub_cat
    ON o.subcategory_id = sub_cat.id;
