--   Inserts a new occurrence into the database
insert into public.occurrence as o (
    applicant_id,
    occurrence_category,
    occurrence_subcategory,
    priority,
    description,
    occurrence_location,
    reference_point
) values (
    $1,
    $2,
    $3,
    $4,
    $5,
    $6,
    $7
)
returning
    o.id,
    o.occurrence_category,
    o.priority,
    o.applicant_id,
    o.created_at;
