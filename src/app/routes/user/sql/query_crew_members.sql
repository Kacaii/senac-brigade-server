-- 󰢫  Retrieves detailed information about fellow brigade members
-- for a given user, including their names and role details.
SELECT
    u.id,
    u.full_name,
    u.user_role,
    cm.brigade_uuid
FROM public.query_crew_members($1) AS cm
INNER JOIN public.user_account AS u
    ON cm.member_uuid = u.id;
