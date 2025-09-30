--   Find all occurrences from the last 24 hours
SELECT
    oc.id,
    oc.created_at,
    oc.description,
    oc_cat.category_name AS category,
    sub_cat.category_name AS subcategory,
    oc.location,
    oc.reference_point
FROM public.occurrence AS oc
LEFT JOIN public.occurrence_category AS oc_cat
    ON oc.category_id = oc_cat.id
LEFT JOIN public.occurrence_category AS sub_cat
    ON oc.subcategory_id = sub_cat.id
WHERE oc.created_at >= (NOW() - '1 day'::INTERVAL);
