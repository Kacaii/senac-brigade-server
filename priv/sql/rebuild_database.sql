--   DROP -------------------------------------------------------------------
BEGIN;

DROP TABLE IF EXISTS ocurrence;
DROP TABLE IF EXISTS ocurrence_type;
DROP TABLE IF EXISTS user_account;
DROP TABLE IF EXISTS user_role;

COMMIT;

--   CREATE -----------------------------------------------------------------
BEGIN;

CREATE TABLE IF NOT EXISTS user_role (
    id UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    name VARCHAR(255) NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS user_account (
    id UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    role_id UUID REFERENCES user_role (id)
    ON UPDATE CASCADE ON DELETE SET NULL,
    full_name VARCHAR(255) NOT NULL,
    password_hash TEXT NOT NULL,
    registration VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT true
);

CREATE TABLE IF NOT EXISTS ocurrence_type (
    id UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    -- This way we dont need to have separate tables for type and subtype
    --                                          vv
    parent_type UUID REFERENCES ocurrence_type (id),
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE IF NOT EXISTS ocurrence (
    id UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    applicant_id UUID REFERENCES user_account (id)
    ON UPDATE CASCADE ON DELETE SET NULL,
    type_id UUID REFERENCES ocurrence_type (id)
    ON UPDATE CASCADE ON DELETE SET NULL,
    subtype_id UUID REFERENCES ocurrence_type (id)
    ON UPDATE CASCADE ON DELETE SET NULL,
    description TEXT,

    -- HACK:   There might be a better way to store this
    address VARCHAR(255) NOT NULL,

    reference_point VARCHAR(255) NOT NULL,
    loss_percentage NUMERIC(2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL
);

COMMIT;
