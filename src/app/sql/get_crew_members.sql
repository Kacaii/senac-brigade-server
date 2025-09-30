-- 󰢫  Retrieves detailed information about fellow brigade members
-- for a given user, including their names and role details.
SELECT
    u.id,
    u.full_name,
    r.role_name,
    r.description
FROM QUERY_FELLOW_BRIGADE_MEMBERS_ID($1) AS crew_members (id)
INNER JOIN
    public.user_account AS u
    ON crew_members.id = u.id
LEFT JOIN
    public.user_role AS r
    ON u.role_id = r.id;
