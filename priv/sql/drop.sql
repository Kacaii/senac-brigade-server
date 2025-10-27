-- VIEWS -----------------------------------------------------------------------
DROP VIEW IF EXISTS vw_count_active_occurrences;
DROP VIEW IF EXISTS vw_count_recent_occurrences;
DROP VIEW IF EXISTS vw_count_total_occurrences;
DROP VIEW IF EXISTS vw_count_active_brigades;

-- TRIGGERS --------------------------------------------------------------------
DROP TRIGGER IF EXISTS tgr_default_notification_preferences
ON user_account;
DROP FUNCTION IF EXISTS public.set_default_notification_preferences;

-- INDEXES ---------------------------------------------------------------------
DROP INDEX IF EXISTS public.idx_brigade_membership_brigade_id;
DROP INDEX IF EXISTS public.idx_brigade_membership_user_id;
DROP INDEX IF EXISTS public.idx_occurrence_applicant_id;
DROP INDEX IF EXISTS public.idx_user_registration;
DROP INDEX IF EXISTS public.idx_occurrence_brigade_brigade_id;
DROP INDEX IF EXISTS public.idx_occurrence_brigade_occurrence_id;
DROP INDEX IF EXISTS public.idx_brigade_leader_id;

-- pgt-ignore-start lint/safety/banDropTable: We are resetting the Database
DROP TABLE IF EXISTS public.occurrence_brigade;
DROP TABLE IF EXISTS public.brigade_membership;
DROP TABLE IF EXISTS public.occurrence_participant;
DROP TABLE IF EXISTS public.occurrence;
DROP TABLE IF EXISTS public.brigade;
DROP TABLE IF EXISTS public.user_notification_preference;
DROP TABLE IF EXISTS public.user_account;
-- pgt-ignore-end lint/safety/banDropTable

-- TYPES -----------------------------------------------------------------------
DROP TYPE IF EXISTS public.NOTIFICATION_TYPE_ENUM;
DROP TYPE IF EXISTS public.OCCURRENCE_CATEGORY_ENUM;
DROP TYPE IF EXISTS public.OCCURRENCE_SUBCATEGORY_ENUM;
DROP TYPE IF EXISTS public.USER_ROLE_ENUM;
DROP TYPE IF EXISTS public.OCCURRENCE_PRIORITY_ENUM;
