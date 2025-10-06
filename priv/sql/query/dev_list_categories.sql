SELECT
    o.category_name,
    o.description,
    o.occurrence_category,
    o.occurrence_subcategory
FROM public.occurrence AS o
LIMIT 20;
