--   Inserts a new occurrence into the database
INSERT INTO public.occurrence AS o (
    applicant_id,
    occurrence_category,
    occurrence_subcategory,
    priority,
    description,
    location,
    reference_point,
    vehicle_code,
    brigade_id
) VALUES (
    $1,
    $2,
    $3,
    $4,
    $5,
    $6,
    $7,
    $8,
    $9
)
RETURNING
    o.id,
    o.priority,
    o.applicant_id,
    o.brigade_id,
    o.created_at;
