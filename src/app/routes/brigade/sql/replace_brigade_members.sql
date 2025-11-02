--   Replace all brigade members
SELECT b.inserted_user_id
FROM public.replace_brigade_members($1, $2) AS b;
