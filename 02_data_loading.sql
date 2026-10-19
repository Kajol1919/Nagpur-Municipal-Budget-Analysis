-- Run this script with psql from the project root folder.
-- Example:
--   psql -h localhost -U postgres -d nagpur_budget -v ON_ERROR_STOP=1 -f sql/02_data_loading.sql
--
-- Paths below are relative to the current working directory (the project root).
-- This uses psql's \copy, so it reads files from the computer running psql.
-- It does not depend on the author's personal Windows path.

TRUNCATE TABLE stg_dim_nagpur, stg_department_nagpur;
TRUNCATE TABLE dim_nagpur_budget, dim_nagpur_department RESTART IDENTITY;


copy stg_dim_nagpur ("Type of Record", "Dept code", "Major Code", "Detailed Code", "Function Description", "2024-25 BE", "2024-25 RE", "2025-26 BE") 
FROM 'data/Dim_Nagpur.csv' 
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

copy stg_department_nagpur ("State", "Municipality", "Dept / Functionary Name", "Dept code")
FROM 'data/Department_Nagpur.csv' 
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');


-- Department_Nagpur.csv contains trailing blank rows. Keep only complete department records.
INSERT INTO dim_nagpur_department (dept_code, state, municipality, department_name)
SELECT DISTINCT
       "Dept code"::INTEGER,
       BTRIM("State"),
       BTRIM("Municipality"),
       BTRIM("Dept / Functionary Name")
FROM stg_department_nagpur
WHERE "Dept code" IS NOT NULL
  AND NULLIF(BTRIM("State"), '') IS NOT NULL
  AND NULLIF(BTRIM("Municipality"), '') IS NOT NULL
  AND NULLIF(BTRIM("Dept / Functionary Name"), '') IS NOT NULL
ON CONFLICT (dept_code) DO UPDATE
SET state = EXCLUDED.state,
    municipality = EXCLUDED.municipality,
    department_name = EXCLUDED.department_name;

-- Preserve missing budget amounts as NULL rather than incorrectly treating them as zero.
INSERT INTO dim_nagpur_budget
    (record_type, dept_code, major_code, detailed_code, function_description,
     be_2024_25, re_2024_25, be_2025_26)
SELECT
    BTRIM("Type of Record"),
    "Dept code",
    "Major Code",
    NULLIF(BTRIM("Detailed Code"), ''),
    BTRIM("Function Description"),
    "2024-25 BE",
    "2024-25 RE",
    "2025-26 BE"
FROM stg_dim_nagpur
WHERE NULLIF(BTRIM("Type of Record"), '') IS NOT NULL
  AND "Dept code" IS NOT NULL
  AND "Major Code" IS NOT NULL
  AND NULLIF(BTRIM("Function Description"), '') IS NOT NULL;

-- Quick post-load counts
SELECT 'budget lines loaded' AS check_name, COUNT(*) AS row_count
FROM dim_nagpur_budget
UNION ALL
SELECT 'departments loaded', COUNT(*)
FROM dim_nagpur_department;
