SELECT o.description
FROM public.occurrence AS o
INNER JOIN public.occurrence_category AS category
    ON
        o.category_id = category.id
        AND o.subcategory_id = category.id
WHERE o.applicant_id = $1
