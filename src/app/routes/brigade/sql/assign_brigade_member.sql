--   Register a user as member of a team
INSERT INTO public.brigade_membership AS bm
(brigade_id, user_id)
VALUES
($1, $2)
ON CONFLICT
(brigade_id, user_id)
DO NOTHING
RETURNING user_id;
