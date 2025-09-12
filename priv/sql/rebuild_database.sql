--   DROP -------------------------------------------------------------------
DROP TABLE IF EXISTS ocurrence;
DROP TABLE IF EXISTS ocurrence_subtype;
DROP TABLE IF EXISTS ocurrence_type;
DROP TABLE IF EXISTS user_account;
DROP TABLE IF EXISTS role;

--   CREATE -----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS role (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS user_account (
    id SERIAL PRIMARY KEY,
    id_role INTEGER REFERENCES role (id)
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
    id SERIAL PRIMARY KEY,
    id_applicant INTEGER REFERENCES user_account (id)
    ON UPDATE CASCADE ON DELETE SET NULL,
    id_type INTEGER REFERENCES ocurrence_type (id)
    ON UPDATE CASCADE ON DELETE SET NULL,
    id_subtype INTEGER REFERENCES ocurrence_subtype (id)
    ON UPDATE CASCADE ON DELETE SET NULL,
    description TEXT,
    address VARCHAR(255) NOT NULL,
    reference_point VARCHAR(255) NOT NULL,
    loss_percentage NUMERIC(2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL
);
