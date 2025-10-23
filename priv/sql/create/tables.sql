BEGIN;

CREATE TYPE public.user_role_enum AS ENUM (
    'admin',
    'analist',
    'firefighter',
    'captain',
    'developer',
    'sargeant'
);

CREATE TABLE IF NOT EXISTS public.user_account (
    id UUID PRIMARY KEY DEFAULT UUIDV7(),
    user_role USER_ROLE_ENUM NOT NULL,
    full_name TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    registration TEXT UNIQUE NOT NULL,
    phone TEXT DEFAULT NULL,
    email TEXT UNIQUE DEFAULT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_registration
ON public.user_account (registration);

CREATE TYPE public.notification_type_enum AS ENUM (
    'fire',
    'emergency',
    'traffic',
    'other'
);

CREATE TABLE IF NOT EXISTS public.notification_preference (
    id UUID PRIMARY KEY DEFAULT UUIDV7(),
    user_id UUID REFERENCES public.user_account (id)
    ON UPDATE CASCADE ON DELETE CASCADE,
    notification_type NOTIFICATION_TYPE_ENUM NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, notification_type)
);

CREATE TABLE IF NOT EXISTS public.brigade (
    id UUID PRIMARY KEY DEFAULT UUIDV7(),
    leader_id UUID REFERENCES public.user_account (id)
    ON UPDATE CASCADE ON DELETE SET NULL,
    vehicle_code TEXT NOT NULL,
    brigade_name TEXT DEFAULT NULL,
    description TEXT DEFAULT NULL,
    members_id UUID [] NOT NULL DEFAULT '{}',
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_brigade_leader_id
ON public.brigade (leader_id);

CREATE TABLE IF NOT EXISTS public.brigade_membership (
    id UUID PRIMARY KEY DEFAULT UUIDV7(),
    user_id UUID REFERENCES public.user_account (id)
    ON UPDATE CASCADE ON DELETE SET NULL,
    brigade_id UUID REFERENCES public.brigade (id)
    ON UPDATE CASCADE ON DELETE CASCADE,
    UNIQUE (user_id, brigade_id)
);

CREATE INDEX IF NOT EXISTS idx_brigade_membership_user_id
ON public.brigade_membership (user_id);

CREATE INDEX IF NOT EXISTS idx_brigade_membership_brigade_id
ON public.brigade_membership (brigade_id);

CREATE TYPE public.occurrence_category_enum AS ENUM (
    'medic_emergency',
    'fire',
    'traffic_accident',
    'other'
);

CREATE TYPE public.occurrence_subcategory_enum AS ENUM (
    -- 󰋠  Medic Emergency,
    'heart_stop',
    'pre_hospital_care',
    'seizure',
    'serious_injury',
    'intoxication',

    --   Fire
    'residential',
    'comercial',
    'vegetation',
    'vehicle',

    --   Traffic Accident
    'collision',
    'run_over',
    'rollover',
    'motorcycle_crash',

    --   Other
    'tree_crash',
    'flood',
    'injured_animal'
);

CREATE TYPE occurrence_priority_enum AS ENUM (
    'low',
    'medium',
    'high'
);

CREATE TABLE IF NOT EXISTS public.occurrence (
    id UUID PRIMARY KEY DEFAULT UUIDV7(),
    applicant_id UUID NOT NULL REFERENCES public.user_account (id)
    ON UPDATE CASCADE ON DELETE CASCADE,
    occurrence_category OCCURRENCE_CATEGORY_ENUM NOT NULL,
    occurrence_subcategory OCCURRENCE_SUBCATEGORY_ENUM,
    priority OCCURRENCE_PRIORITY_ENUM NOT NULL,
    description TEXT,
    occurrence_location FLOAT [],
    reference_point TEXT,
    brigade_list UUID [] NOT NULL DEFAULT '{}',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    arrived_at TIMESTAMP DEFAULT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP DEFAULT NULL
);

CREATE INDEX IF NOT EXISTS idx_occurrence_applicant_id
ON public.occurrence (applicant_id);

CREATE TABLE IF NOT EXISTS public.occurrence_brigade_member (
    id UUID PRIMARY KEY DEFAULT UUIDV7(),
    user_id UUID REFERENCES public.user_account (id)
    ON UPDATE CASCADE ON DELETE CASCADE,
    occurrence_id UUID REFERENCES public.occurrence (id)
    ON UPDATE CASCADE ON DELETE CASCADE,
    UNIQUE (occurrence_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_occurrence_brigade_member_user_id
ON public.occurrence_brigade_member (user_id);

CREATE INDEX IF NOT EXISTS idx_occurrence_brigade_member_occurrence_id
ON public.occurrence_brigade_member (occurrence_id);

COMMIT;
