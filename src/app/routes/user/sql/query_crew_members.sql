-- 󰢫  Retrieves detailed information about fellow brigade members
-- for a given user, including their names and role details.
SELECT
    u.id,
    u.full_name,
    u.user_role
FROM public.query_crew_members($1) AS crew_members (id)
INNER JOIN
    public.user_account AS u
    ON crew_members.id = u.id
