--   Inserts a new occurrence into the database
INSERT INTO public.occurrence AS o (
    applicant_id,
    occurrence_category,
    occurrence_subcategory,
    priority,
    description,
    occurrence_location,
    reference_point,
    brigade_list
) VALUES (
    $1,
    $2,
    $3,
    $4,
    $5,
    $6,
    $7,
    $8
)
RETURNING
    o.id,
    o.priority,
    o.applicant_id,
    o.brigade_list,
    o.created_at;
