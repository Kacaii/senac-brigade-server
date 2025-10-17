--   Remove an occurence from the database
DELETE FROM public.occurrence AS o
WHERE o.id = $1
RETURNING o.id;
