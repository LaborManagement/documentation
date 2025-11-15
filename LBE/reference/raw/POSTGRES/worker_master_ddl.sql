--drop table
DROP TABLE IF EXISTS payment_flow.worker_master;

CREATE TABLE IF NOT EXISTS payment_flow.worker_master (
    id BIGSERIAL PRIMARY KEY,
    worker_name_marathi        VARCHAR(120) NOT NULL,
    worker_name_english        VARCHAR(120),
    witness_name_1             VARCHAR(120),
    witness_name_2             VARCHAR(120),
    toli_number                VARCHAR(64),
    registration_number        VARCHAR(64) NOT NULL,
    pan_number                 VARCHAR(16),
    nationality                VARCHAR(100),
    mother_name                VARCHAR(120),
    mobile_number              VARCHAR(15),
    mobile_number_1            VARCHAR(15),
    marital_status             VARCHAR(30),
    ifsc_code                  VARCHAR(11),
    branch_address             VARCHAR(255),
    bank_name                  VARCHAR(120),
    age                        INTEGER,
    address1                   VARCHAR(255),
    address2                   VARCHAR(255),
    account_number             VARCHAR(64),
    aadhar_number              CHAR(12) NOT NULL,
    status                     VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    created_at                 TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at                 TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT worker_master_registration_number UNIQUE (registration_number),
    CONSTRAINT worker_master_aadhar_number UNIQUE (aadhar_number)
);

COMMENT ON TABLE payment_flow.worker_master IS 'Holds demographic and banking details for registered workers.';
