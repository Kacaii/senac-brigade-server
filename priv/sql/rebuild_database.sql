--   DROP -------------------------------------------------------------------
BEGIN;

DROP INDEX IF EXISTS idx_brigade_membership_brigade_id;
DROP INDEX IF EXISTS idx_brigade_membership_user_id;
DROP INDEX IF EXISTS idx_occurrence_applicant_id;
DROP INDEX IF EXISTS idx_user_registration;

DROP TABLE IF EXISTS occurrence;
DROP TABLE IF EXISTS occurrence_category;
DROP TABLE IF EXISTS brigade_membership;
DROP TABLE IF EXISTS brigade;
DROP TABLE IF EXISTS user_account;
DROP TABLE IF EXISTS user_role;

--   CREATE -----------------------------------------------------------------

CREATE TABLE IF NOT EXISTS user_role (
    id UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    role_name TEXT NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS user_account (
    id UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    role_id UUID REFERENCES user_role (id)
    ON UPDATE CASCADE ON DELETE SET NULL DEFAULT NULL,
    full_name TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    registration TEXT UNIQUE NOT NULL,
    phone TEXT DEFAULT NULL,
    email TEXT UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_registration ON user_account (registration);

CREATE TABLE IF NOT EXISTS brigade (
    id UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    brigade_name TEXT DEFAULT NULL,
    description TEXT DEFAULT NULL,
    is_active BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS brigade_membership (
    id UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    user_id UUID REFERENCES user_account (id)
    ON UPDATE CASCADE ON DELETE SET NULL,
    brigade_id UUID REFERENCES brigade (id)
    ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_brigade_membership_user_id
ON brigade_membership (user_id);

CREATE INDEX IF NOT EXISTS idx_brigade_membership_brigade_id
ON brigade_membership (brigade_id);


CREATE TABLE IF NOT EXISTS occurrence_category (
    id UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    parent_category UUID REFERENCES occurrence_category (id)
    ON UPDATE CASCADE ON DELETE CASCADE DEFAULT NULL,
    category_name TEXT UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS occurrence (
    id UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    applicant_id UUID REFERENCES user_account (id)
    ON UPDATE CASCADE ON DELETE SET NULL,
    category_id UUID REFERENCES occurrence_category (id)
    ON UPDATE CASCADE ON DELETE SET NULL,
    subcategory_id UUID REFERENCES occurrence_category (id)
    ON UPDATE CASCADE ON DELETE SET NULL DEFAULT NULL,
    description TEXT,
    location POINT NOT NULL,
    reference_point TEXT NOT NULL,
    loss_percentage NUMERIC(2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
);

CREATE INDEX IF NOT EXISTS idx_occurrence_applicant_id
ON occurrence (applicant_id);

COMMIT;
