--   Remove a brigade from the DataBase
DELETE FROM public.brigade AS b
WHERE b.id = $1
RETURNING
    b.id,
    b.brigade_name;
