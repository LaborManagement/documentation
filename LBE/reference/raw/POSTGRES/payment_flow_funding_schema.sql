-- Employer funding schema for payment-flow-service
-- Reuse the existing payment_flow schema so no new Postgres schema is needed.
CREATE SCHEMA IF NOT EXISTS payment_flow;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- NOTE: employer_master already exists (see EmployerMaster entity in master module)
-- and is assumed to live in the payment_flow schema.

CREATE TABLE IF NOT EXISTS payment_flow.employer_fund_acct (
    fund_acct_id         BIGSERIAL PRIMARY KEY,
    employer_master_id   BIGINT NOT NULL
        REFERENCES payment_flow.employer_master (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    account_code         TEXT NOT NULL,
    account_type         TEXT NOT NULL
        CHECK (account_type IN ('van', 'direct')),
    currency_code        CHAR(3) NOT NULL,
    status               TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'sunsetting', 'closed')),
    display_name         TEXT,
    account_identifier   TEXT,
    default_for_type     BOOLEAN NOT NULL DEFAULT FALSE,
    metadata             JSONB,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    closed_at            TIMESTAMPTZ,
    UNIQUE (employer_master_id, account_code),
    UNIQUE (account_identifier) WHERE account_identifier IS NOT NULL,
    CONSTRAINT employer_fund_acct_default_once
        UNIQUE (employer_master_id, account_type)
        DEFERRABLE INITIALLY DEFERRED
        WHERE default_for_type
);

CREATE INDEX IF NOT EXISTS idx_employer_fund_acct_employer
    ON payment_flow.employer_fund_acct (employer_master_id);

CREATE INDEX IF NOT EXISTS idx_employer_fund_acct_type_status
    ON payment_flow.employer_fund_acct (account_type, status);

CREATE TABLE IF NOT EXISTS payment_flow.employer_fund_txn (
    fund_txn_id          BIGSERIAL PRIMARY KEY,
    fund_acct_id         BIGINT NOT NULL
        REFERENCES payment_flow.employer_fund_acct (fund_acct_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    txn_type             TEXT NOT NULL
        CHECK (txn_type IN ('credit', 'debit', 'reversal')),
    source_system        TEXT NOT NULL,
    source_reference     TEXT,
    employer_reference   TEXT,
    request_id           UUID,
    payout_id            UUID,
    amount               NUMERIC(20, 4) NOT NULL CHECK (amount > 0),
    currency_code        CHAR(3) NOT NULL,
    value_date           DATE NOT NULL,
    available_on         DATE,
    status               TEXT NOT NULL DEFAULT 'posted'
        CHECK (status IN ('pending', 'posted', 'void')),
    metadata             JSONB,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (fund_acct_id, source_system, source_reference)
        WHERE source_reference IS NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_employer_fund_txn_acct_date
    ON payment_flow.employer_fund_txn (fund_acct_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_employer_fund_txn_request
    ON payment_flow.employer_fund_txn (request_id);

CREATE INDEX IF NOT EXISTS idx_employer_fund_txn_reference
    ON payment_flow.employer_fund_txn (employer_reference)
    WHERE employer_reference IS NOT NULL;

COMMENT ON TABLE payment_flow.employer_fund_acct IS
    'Logical wallet per employer (VAN or direct).';

COMMENT ON TABLE payment_flow.employer_fund_txn IS
    'Ledger of credits/debits for each funding account to support reconciliation.';
