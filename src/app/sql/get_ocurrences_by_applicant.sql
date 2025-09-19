SELECT o.description
FROM occurrence AS o
INNER JOIN occurrence_category AS ot
    ON
        o.category_id = ot.id
        AND o.subcategory_id = ot.id
WHERE o.applicant_id = $1
