-- 󱘟  Retrieve stats for the Dashboard page
select
    (select count from public.vw_count_active_brigades)
        as active_brigades_count,
    (select count from public.vw_count_total_occurrences)
        as total_occurrences_count,
    (select count from public.vw_count_active_occurrences)
        as active_occurrences_count,
    (select count from public.vw_count_recent_occurrences)
        as recent_occurrences_count;
