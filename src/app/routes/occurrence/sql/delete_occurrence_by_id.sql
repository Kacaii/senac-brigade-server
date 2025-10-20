DELETE FROM public.occurrence AS o
Where o.id = $1
RETURNING o.id;

