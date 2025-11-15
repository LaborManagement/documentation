-- Employer master DDL for Postgres
CREATE SCHEMA IF NOT EXISTS payment_flow;

CREATE TABLE IF NOT EXISTS payment_flow.employer_master (
    id BIGSERIAL PRIMARY KEY,
    registration_number            VARCHAR(64)  NOT NULL,
    establishment_name             VARCHAR(200) NOT NULL,
    address                        VARCHAR(255),
    employer_name                  VARCHAR(120),
    mobile_number                  VARCHAR(15),
    email_id                       VARCHAR(150),
    aadhar_number                  CHAR(12),
    pan_number                     VARCHAR(16),
    tan_number                     VARCHAR(10),
    virtual_bank_account_number    VARCHAR(64),
    status                         VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    created_at                     TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at                     TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT employer_master_registration_number UNIQUE (registration_number),
    CONSTRAINT employer_master_aadhar_number UNIQUE (aadhar_number),
    CONSTRAINT employer_master_virtual_bank_account UNIQUE (virtual_bank_account_number)
);

COMMENT ON TABLE payment_flow.employer_master IS 'Stores establishment, contact, and compliance details for employers.';

CREATE OR REPLACE FUNCTION payment_flow.set_employer_master_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_employer_master_set_updated_at ON payment_flow.employer_master;
CREATE TRIGGER trg_employer_master_set_updated_at
BEFORE UPDATE ON payment_flow.employer_master
FOR EACH ROW
EXECUTE FUNCTION payment_flow.set_employer_master_updated_at();
