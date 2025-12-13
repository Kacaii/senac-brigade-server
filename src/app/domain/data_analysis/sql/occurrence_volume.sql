-- 󰕮  Occurrence reports
select
    o.id as occurrence_id,
    o.created_at as reported_timestamp,
    o.arrived_at as arrival_timestamp,
    o.resolved_at as resolved_timestamp,
    o.occurrence_category,
    o.occurrence_subcategory,
    o.priority,
    u_applicant.full_name as applicant_name,
    u_applicant.user_role as applicant_role,
    o.occurrence_location[1] as latitude,
    o.occurrence_location[2] as longitude
from
    public.occurrence as o
left join
    public.user_account as u_applicant
    on o.applicant_id = u_applicant.id
order by
    o.created_at desc;
