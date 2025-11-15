-- Creates the employer_fund_txn table used to persist VAN/MT940 derived employer deposits.
-- The table is linked to the employee master via emp_id, ensuring fund balances
-- can be attributed to the correct employer/employee entity inside the payment service.

CREATE TABLE IF NOT EXISTS employer_fund_txn (
    emp_id           BIGINT      NOT NULL,
    txn_ref          VARCHAR(64) NOT NULL,
    amnt             NUMERIC(19,2) NOT NULL CHECK (amnt >= 0),
    utilized         NUMERIC(19,2) NOT NULL DEFAULT 0 CHECK (utilized >= 0),
    un_utilized      NUMERIC(19,2) NOT NULL DEFAULT 0 CHECK (un_utilized >= 0),
    type             VARCHAR(32) NOT NULL,
    status           VARCHAR(32) NOT NULL,
    rec_ref          VARCHAR(64),
    CONSTRAINT pk_employer_fund_txn PRIMARY KEY (emp_id, txn_ref),
    CONSTRAINT fk_employer_fund_txn_emp FOREIGN KEY (emp_id)
        REFERENCES employee_master(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_employer_fund_txn_utilization
        CHECK (utilized <= amnt AND un_utilized = amnt - utilized)
);

CREATE INDEX IF NOT EXISTS idx_employer_fund_txn_txn_ref ON employer_fund_txn (txn_ref);
CREATE INDEX IF NOT EXISTS idx_employer_fund_txn_status ON employer_fund_txn (status);
CREATE INDEX IF NOT EXISTS idx_employer_fund_txn_rec_ref ON employer_fund_txn (rec_ref);

-- Captures individual worker advance transactions that accompany worker payment uploads.
-- Ties each advance back to employer, toli, worker, and board masters so outstanding
-- advances can be reconciled before payouts are triggered.

CREATE TABLE IF NOT EXISTS worker_advance_txn (
    id               BIGSERIAL PRIMARY KEY,
    adv_ref          VARCHAR(64) NOT NULL,
    emp_id           VARCHAR(64) NOT NULL,
    toli_id          VARCHAR(64) NOT NULL,
    worker_id        VARCHAR(64) NOT NULL,
    board_id         VARCHAR(64),
    adv_amnt         NUMERIC(19,2) NOT NULL CHECK (adv_amnt >= 0),
    receipt_nmbr     VARCHAR(64),
    status           VARCHAR(32) NOT NULL DEFAULT 'PENDING',
    upload_ref       VARCHAR(64),
    remarks          TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_worker_advance_txn_ref UNIQUE (adv_ref),
    CONSTRAINT fk_worker_advance_txn_emp FOREIGN KEY (emp_id)
        REFERENCES employer_master (employer_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_worker_advance_txn_toli FOREIGN KEY (toli_id)
        REFERENCES toli_master (toli_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_worker_advance_txn_worker FOREIGN KEY (worker_id)
        REFERENCES worker_master (worker_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_worker_advance_txn_board FOREIGN KEY (board_id)
        REFERENCES board_master (board_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_worker_advance_txn_status ON worker_advance_txn (status);
CREATE INDEX IF NOT EXISTS idx_worker_advance_txn_worker ON worker_advance_txn (worker_id);
CREATE INDEX IF NOT EXISTS idx_worker_advance_txn_receipt ON worker_advance_txn (receipt_nmbr);
