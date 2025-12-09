--   Retrieves all occurrences associated with a user,
-- including detailed category information and resolution status.
select
    o.id,
    o.resolved_at,
    o.priority,
    o.occurrence_category,
    o.occurrence_location,
    o.description as details,
    u.full_name as applicant_name,
    o.created_at,
    o.arrived_at,
    u.registration as applicant_registration,
    o.applicant_id,

    (
        select json_agg(json_build_object(
            'id', b.id,
            'brigade_name', b.brigade_name,
            'leader_full_name', leader_u.full_name,
            'vehicle_code', b.vehicle_code
        )) from public.occurrence_brigade as ob
        inner join public.brigade as b
            on ob.brigade_id = b.id
        inner join public.user_account as leader_u
            on b.leader_id = leader_u.id
        where ob.occurrence_id = o.id
    ) as brigade_list

from public.occurrence as o
inner join public.user_account as u
    on o.applicant_id = u.id
where o.applicant_id = $1;
