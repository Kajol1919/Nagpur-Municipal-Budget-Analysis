-- Nagpur Municipal Budget Analysis
-- PostgreSQL schema. Run this first.
-- Raw staging tables preserve source-file rows; reporting tables hold usable records.

BEGIN;

DROP TABLE IF EXISTS stg_dim_nagpur;
DROP TABLE IF EXISTS stg_department_nagpur;
DROP TABLE IF EXISTS dim_nagpur_budget;
DROP TABLE IF EXISTS dim_nagpur_department;

CREATE TABLE stg_dim_nagpur (
    "Type of Record"       TEXT,
    "Dept code"            INTEGER,
    "Major Code"           INTEGER,
    "Detailed Code"        TEXT,
    "Function Description" TEXT,
    "2024-25 BE"           NUMERIC(14,2),
    "2024-25 RE"           NUMERIC(14,2),
    "2025-26 BE"           NUMERIC(14,2)
);

CREATE TABLE stg_department_nagpur (
    "State"                 TEXT,
    "Municipality"          TEXT,
    "Dept / Functionary Name" TEXT,
    "Dept code"              NUMERIC(10,0)
);

CREATE TABLE dim_nagpur_department (
    dept_code       INTEGER PRIMARY KEY,
    state           TEXT NOT NULL,
    municipality    TEXT NOT NULL,
    department_name TEXT NOT NULL
);

CREATE TABLE dim_nagpur_budget (
    budget_line_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    record_type    TEXT NOT NULL CHECK (record_type IN ('Income', 'Expenses', 'Liability', 'Asset')),
    dept_code      INTEGER NOT NULL,
    major_code     INTEGER NOT NULL,
    detailed_code  TEXT,
    function_description TEXT NOT NULL,
    be_2024_25     NUMERIC(14,2),
    re_2024_25     NUMERIC(14,2),
    be_2025_26     NUMERIC(14,2),
    CONSTRAINT fk_budget_department
        FOREIGN KEY (dept_code) REFERENCES dim_nagpur_department(dept_code)
);

CREATE INDEX idx_budget_dept_code ON dim_nagpur_budget(dept_code);
CREATE INDEX idx_budget_record_type ON dim_nagpur_budget(record_type);
CREATE INDEX idx_budget_major_code ON dim_nagpur_budget(major_code);

COMMIT;
