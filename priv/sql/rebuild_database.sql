--   DROP -------------------------------------------------------------------
BEGIN;

DROP TABLE IF EXISTS ocurrence;
DROP TABLE IF EXISTS ocurrence_subtype;
DROP TABLE IF EXISTS ocurrence_type;
DROP TABLE IF EXISTS user_account;
DROP TABLE IF EXISTS user_role;

COMMIT;

--   CREATE -----------------------------------------------------------------
BEGIN;

CREATE TABLE IF NOT EXISTS user_role (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS user_account (
    id UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    role_id INTEGER REFERENCES user_role (id)
    ON UPDATE CASCADE ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    password_hash TEXT NOT NULL,
    registration VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    is_active BOOLEAN DEFAULT true
);

CREATE TABLE IF NOT EXISTS ocurrence_type (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ocurrence_subtype (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ocurrence (
    id UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    applicant_id UUID REFERENCES user_account (id)
    ON UPDATE CASCADE ON DELETE SET NULL,
    type_id INTEGER REFERENCES ocurrence_type (id)
    ON UPDATE CASCADE ON DELETE SET NULL,
    subtype_id INTEGER REFERENCES ocurrence_subtype (id)
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
