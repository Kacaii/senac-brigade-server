--   Retrieves all occurrences associated with a user,
-- including detailed category information and resolution status.
SELECT
    o.id,
    o.resolved_at,
    o.priority,
    o.occurrence_category,
    o.occurrence_location,
    o.description AS details,
    u.full_name AS applicant_name,
    o.created_at,
    o.arrived_at,
    u.registration AS applicant_registration,
    o.applicant_id,
    (
        SELECT JSON_AGG(JSON_BUILD_OBJECT(
            'id', b.id,
            'leader_full_name', leader_u.full_name,
            'vehicle_code', b.vehicle_code
        )) FROM public.brigade AS b
        INNER JOIN public.user_account AS leader_u
            ON b.leader_id = leader_u.id
        WHERE b.id = ANY(o.brigade_list)
    ) AS brigade_list

FROM public.occurrence AS o
INNER JOIN public.user_account AS u
    ON o.applicant_id = u.id
WHERE o.applicant_id = $1;
