-- 󰆙  Counts the number of active occurrences
SELECT COUNT(oc.id)
FROM public.occurrence AS oc
WHERE oc.resolved_at IS NULL;
