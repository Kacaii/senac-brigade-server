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
            'brigade_name', b.brigade_name,
            'leader_full_name', leader_u.full_name,
            'vehicle_code', b.vehicle_code
        )) FROM public.occurrence_brigade AS ob
        INNER JOIN public.brigade AS b
            ON ob.brigade_id = b.id
        INNER JOIN public.user_account AS leader_u
            ON b.leader_id = leader_u.id
        WHERE ob.occurrence_id = o.id
    ) AS brigade_list

FROM public.occurrence AS o
INNER JOIN public.user_account AS u
    ON o.applicant_id = u.id
WHERE o.applicant_id = $1;
