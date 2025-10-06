--   Inserts a new occurrence into the database
INSERT INTO public.occurrence (
    applicant_id,
    occurrence_category,
    occurrence_subcategory,
    description,
    location,
    reference_point,
    vehicle_code,
    participants_id
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
RETURNING id, created_at;
