-- 󰆙  Counts the number of active brigades in the database.
SELECT COUNT(id)
FROM public.brigade
WHERE is_active = TRUE;
