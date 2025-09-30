--   DROP -------------------------------------------------------------------
BEGIN;

DROP INDEX IF EXISTS public.idx_brigade_membership_brigade_id;
DROP INDEX IF EXISTS public.idx_brigade_membership_user_id;
DROP INDEX IF EXISTS public.idx_occurrence_applicant_id;
DROP INDEX IF EXISTS public.idx_user_registration;
DROP INDEX IF EXISTS public.idx_user_id;
DROP INDEX IF EXISTS public.idx_occurrence_id;
DROP INDEX IF EXISTS public.idx_occurrence_brigade_member_user_id;
DROP INDEX IF EXISTS public.idx_occurrence_brigade_member_occurrence_id;

-- pgt-ignore-start lint/safety/banDropTable: We are resetting the Database
DROP TABLE IF EXISTS public.occurrence;
DROP TABLE IF EXISTS public.occurrence_category;
DROP TABLE IF EXISTS public.occurrence_brigade_member;
DROP TABLE IF EXISTS public.brigade_membership;
DROP TABLE IF EXISTS public.brigade;
DROP TABLE IF EXISTS public.user_account;
DROP TABLE IF EXISTS public.user_role;
-- pgt-ignore-end lint/safety/banDropTable

--   CREATE -----------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.user_role (
    id UUID PRIMARY KEY DEFAULT UUIDV7(),
    role_name TEXT NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS public.user_account (
    id UUID PRIMARY KEY DEFAULT UUIDV7(),
    role_id UUID REFERENCES public.user_role (id)
    ON UPDATE CASCADE ON DELETE SET NULL DEFAULT NULL,
    full_name TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    registration TEXT UNIQUE NOT NULL,
    phone TEXT DEFAULT NULL,
    email TEXT UNIQUE DEFAULT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_registration
ON public.user_account (registration);

CREATE TABLE IF NOT EXISTS public.brigade (
    id UUID PRIMARY KEY DEFAULT UUIDV7(),
    brigade_name TEXT DEFAULT NULL,
    description TEXT DEFAULT NULL,
    is_active BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS public.brigade_membership (
    id UUID PRIMARY KEY DEFAULT UUIDV7(),
    user_id UUID REFERENCES public.user_account (id)
    ON UPDATE CASCADE ON DELETE SET NULL,
    brigade_id UUID REFERENCES public.brigade (id)
    ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_brigade_membership_user_id
ON public.brigade_membership (user_id);

CREATE INDEX IF NOT EXISTS idx_brigade_membership_brigade_id
ON public.brigade_membership (brigade_id);

CREATE TABLE IF NOT EXISTS public.occurrence_category (
    id UUID PRIMARY KEY DEFAULT UUIDV7(),
    parent_category_id UUID REFERENCES public.occurrence_category (id)
    ON UPDATE CASCADE ON DELETE CASCADE DEFAULT NULL,
    category_name TEXT UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.occurrence (
    id UUID PRIMARY KEY DEFAULT UUIDV7(),
    applicant_id UUID REFERENCES public.user_account (id)
    ON UPDATE CASCADE ON DELETE SET NULL,
    category_id UUID REFERENCES public.occurrence_category (id)
    ON UPDATE CASCADE ON DELETE SET NULL,
    subcategory_id UUID REFERENCES public.occurrence_category (id)
    ON UPDATE CASCADE ON DELETE SET NULL DEFAULT NULL,
    description TEXT,
    location POINT NOT NULL,
    reference_point TEXT,
    vehicle_code TEXT NOT NULL,
    participants_id UUID [],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP DEFAULT NULL
);

CREATE INDEX IF NOT EXISTS idx_occurrence_applicant_id
ON public.occurrence (applicant_id);

CREATE TABLE IF NOT EXISTS public.occurrence_brigade_member (
    id UUID PRIMARY KEY DEFAULT UUIDV7(),
    user_id UUID REFERENCES public.user_account (id)
    ON UPDATE CASCADE,
    occurrence_id UUID REFERENCES public.user_account (id)
    ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_occurrence_brigade_member_user_id
ON public.occurrence_brigade_member (user_id);

CREATE INDEX IF NOT EXISTS idx_occurrence_brigade_member_occurrence_id
ON public.occurrence_brigade_member (occurrence_id);

COMMIT;
