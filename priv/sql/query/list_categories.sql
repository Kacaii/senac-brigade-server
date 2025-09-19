SELECT
    c.category_name,
    c.description,
    parent.category_name AS parent_category_name
FROM occurrence_category AS c
LEFT JOIN occurrence_category AS parent ON c.parent_category_id = parent.id
LIMIT 20;
