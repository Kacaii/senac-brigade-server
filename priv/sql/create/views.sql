CREATE OR REPLACE VIEW vw_count_active_occurrences AS
SELECT COUNT(oc.id) AS count
FROM public.occurrence AS oc
WHERE oc.resolved_at IS NULL;

-----------------------------------------------------
CREATE OR REPLACE VIEW vw_count_recent_occurrences AS
SELECT COUNT(oc.id) AS count
FROM public.occurrence AS oc
WHERE oc.created_at >= (NOW() - '1 day'::INTERVAL);

----------------------------------------------------
CREATE OR REPLACE VIEW vw_count_total_occurrences AS
SELECT COUNT(oc.id) AS count
FROM public.occurrence AS oc;

------------------------------------------------------
CREATE OR REPLACE VIEW vw_count_active_brigades AS
SELECT COUNT(id)
FROM public.brigade
WHERE is_active = TRUE;
