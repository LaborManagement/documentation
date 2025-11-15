-- Toli master DDL for Postgres
CREATE SCHEMA IF NOT EXISTS payment_flow;

CREATE TABLE IF NOT EXISTS payment_flow.toli_master (
    id BIGSERIAL PRIMARY KEY,
    registration_number        VARCHAR(64)  NOT NULL,
    employer_name_marathi      VARCHAR(200) NOT NULL,
    address                    VARCHAR(255),
    employer_name_english      VARCHAR(200),
    mobile_number              VARCHAR(15),
    email_id                   VARCHAR(150),
    status                     VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    created_at                 TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at                 TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT toli_master_registration_number UNIQUE (registration_number)
);

COMMENT ON TABLE payment_flow.toli_master IS 'Captures employer (toli) level details for registration and communication.';

CREATE OR REPLACE FUNCTION payment_flow.set_toli_master_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_toli_master_set_updated_at ON payment_flow.toli_master;
CREATE TRIGGER trg_toli_master_set_updated_at
BEFORE UPDATE ON payment_flow.toli_master
FOR EACH ROW
EXECUTE FUNCTION payment_flow.set_toli_master_updated_at();
