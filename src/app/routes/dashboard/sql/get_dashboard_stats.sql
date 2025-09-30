-- 
SELECT
    (
        SELECT count
        FROM public.vw_count_active_brigades
    ) AS active_brigades_count,
    (
        SELECT count
        FROM public.vw_count_total_occurrences
    ) AS total_occurrences_count,
    (
        SELECT count
        FROM public.vw_count_active_occurrences
    ) AS active_occurrences_count,
    (
        SELECT count FROM
            public.vw_count_recent_occurrences
    ) AS recent_occurrences_count;
