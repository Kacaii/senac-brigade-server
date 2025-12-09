-- VIEWS -----------------------------------------------------------------------
drop view if exists vw_count_active_occurrences;
drop view if exists vw_count_recent_occurrences;
drop view if exists vw_count_total_occurrences;
drop view if exists vw_count_active_brigades;

-- TRIGGERS --------------------------------------------------------------------
drop trigger if exists tgr_default_notification_preferences
on user_account;
drop function if exists public.set_default_notification_preferences;

-- pgt-ignore-start lint/safety/banDropTable: We are resetting the Database
drop table if exists public.occurrence_brigade;
drop table if exists public.brigade_membership;
drop table if exists public.occurrence;
drop table if exists public.brigade;
drop table if exists public.user_notification_preference;
drop table if exists public.user_account;
-- pgt-ignore-end lint/safety/banDropTable

-- TYPES -----------------------------------------------------------------------
drop type if exists public.notification_type_enum;
drop type if exists public.occurrence_category_enum;
drop type if exists public.occurrence_subcategory_enum;
drop type if exists public.user_role_enum;
drop type if exists public.occurrence_priority_enum;
