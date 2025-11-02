--   Assign a list of members to a brigade
SELECT b.inserted_user_id
FROM public.assign_brigade_members($1, $2) AS b;
