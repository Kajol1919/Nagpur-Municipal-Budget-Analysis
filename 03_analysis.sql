-- Nagpur Municipal Budget Analysis
-- Run after 01_schema.sql and 02_data_loading.sql.
-- Amounts are shown in the same units as the supplied CSV; no currency unit is assumed.

-- 01. Overall totals by record type across the three available budget columns.
SELECT record_type,
       SUM(be_2024_25) AS total_2024_25_be,
       SUM(re_2024_25) AS total_2024_25_re,
       SUM(be_2025_26) AS total_2025_26_be
FROM dim_nagpur_budget
GROUP BY record_type
ORDER BY total_2025_26_be DESC NULLS LAST;

-- 02. Department-wise 2025-26 budget estimate by record type.
SELECT d.department_name, b.record_type,
       COUNT(*) AS budget_line_count,
       SUM(b.be_2025_26) AS total_2025_26_be
FROM dim_nagpur_budget b
JOIN dim_nagpur_department d USING (dept_code)
GROUP BY d.department_name, b.record_type
ORDER BY d.department_name, total_2025_26_be DESC NULLS LAST;

-- 03. Top departments by 2025-26 expense budget.
SELECT d.department_name,
       SUM(b.be_2025_26) AS expense_budget_2025_26
FROM dim_nagpur_budget b
JOIN dim_nagpur_department d USING (dept_code)
WHERE b.record_type = 'Expenses'
GROUP BY d.department_name
ORDER BY expense_budget_2025_26 DESC NULLS LAST
LIMIT 10;

-- 04. Compare 2024-25 Budget Estimate (BE) with Revised Estimate (RE) by record type.
SELECT record_type,
       SUM(be_2024_25) AS total_be,
       SUM(re_2024_25) AS total_re,
       SUM(re_2024_25) - SUM(be_2024_25) AS revision_amount,
       ROUND(
         100.0 * (SUM(re_2024_25) - SUM(be_2024_25))
         / NULLIF(SUM(be_2024_25), 0), 2
       ) AS revision_pct
FROM dim_nagpur_budget
GROUP BY record_type
ORDER BY revision_amount DESC NULLS LAST;

-- 05. Compare the latest estimate (2025-26 BE) with the previous revised estimate (2024-25 RE).
SELECT record_type,
       SUM(re_2024_25) AS total_2024_25_re,
       SUM(be_2025_26) AS total_2025_26_be,
       SUM(be_2025_26) - SUM(re_2024_25) AS year_over_year_change,
       ROUND(
         100.0 * (SUM(be_2025_26) - SUM(re_2024_25))
         / NULLIF(SUM(re_2024_25), 0), 2
       ) AS change_pct
FROM dim_nagpur_budget
GROUP BY record_type
ORDER BY year_over_year_change DESC NULLS LAST;

-- 06. Largest individual budget lines in the 2025-26 estimate.
SELECT d.department_name, b.record_type, b.major_code, b.detailed_code,
       b.function_description, b.be_2025_26
FROM dim_nagpur_budget b
JOIN dim_nagpur_department d USING (dept_code)
WHERE b.be_2025_26 IS NOT NULL
ORDER BY b.be_2025_26 DESC
LIMIT 15;

-- 07. Budget lines with the largest increase from 2024-25 RE to 2025-26 BE.
SELECT d.department_name, b.record_type, b.function_description,
       b.re_2024_25, b.be_2025_26,
       b.be_2025_26 - b.re_2024_25 AS change_amount
FROM dim_nagpur_budget b
JOIN dim_nagpur_department d USING (dept_code)
WHERE b.re_2024_25 IS NOT NULL
  AND b.be_2025_26 IS NOT NULL
ORDER BY change_amount DESC
LIMIT 15;

-- 08. Budget lines with the largest decrease from 2024-25 RE to 2025-26 BE.
SELECT d.department_name, b.record_type, b.function_description,
       b.re_2024_25, b.be_2025_26,
       b.be_2025_26 - b.re_2024_25 AS change_amount
FROM dim_nagpur_budget b
JOIN dim_nagpur_department d USING (dept_code)
WHERE b.re_2024_25 IS NOT NULL
  AND b.be_2025_26 IS NOT NULL
ORDER BY change_amount ASC
LIMIT 15;

-- 09. Each record type's share of the total 2025-26 estimate.
WITH type_totals AS (
    SELECT record_type, SUM(be_2025_26) AS amount
    FROM dim_nagpur_budget
    GROUP BY record_type
)
SELECT record_type, amount,
       ROUND(100.0 * amount / NULLIF(SUM(amount) OVER (), 0), 2) AS share_pct
FROM type_totals
ORDER BY amount DESC NULLS LAST;

-- 10. Major-code analysis by record type for 2025-26 BE.
SELECT record_type, major_code,
       COUNT(*) AS line_count,
       SUM(be_2025_26) AS total_2025_26_be
FROM dim_nagpur_budget
GROUP BY record_type, major_code
HAVING COUNT(*) >= 2
ORDER BY record_type, total_2025_26_be DESC NULLS LAST;

-- 11. Categorize budget lines by their 2025-26 estimate.
SELECT
    CASE
      WHEN be_2025_26 IS NULL THEN 'Missing estimate'
      WHEN be_2025_26 = 0 THEN 'Zero'
      WHEN be_2025_26 < 100 THEN 'Below 100'
      WHEN be_2025_26 < 1000 THEN '100 to below 1,000'
      ELSE '1,000 and above'
    END AS estimate_band,
    COUNT(*) AS line_count,
    SUM(be_2025_26) AS band_total
FROM dim_nagpur_budget
GROUP BY 1
ORDER BY MIN(
    CASE
      WHEN be_2025_26 IS NULL THEN 1
      WHEN be_2025_26 = 0 THEN 2
      WHEN be_2025_26 < 100 THEN 3
      WHEN be_2025_26 < 1000 THEN 4
      ELSE 5
    END
);

-- 12. Rank departments within each record type by 2025-26 BE.
WITH department_totals AS (
    SELECT b.record_type, d.department_name,
           SUM(b.be_2025_26) AS total_2025_26_be
    FROM dim_nagpur_budget b
    JOIN dim_nagpur_department d USING (dept_code)
    GROUP BY b.record_type, d.department_name
)
SELECT record_type, department_name, total_2025_26_be,
       DENSE_RANK() OVER (
           PARTITION BY record_type
           ORDER BY total_2025_26_be DESC NULLS LAST
       ) AS department_rank
FROM department_totals
ORDER BY record_type, department_rank;

-- 13. Top three budget lines per department and record type (window function).
WITH ranked_lines AS (
    SELECT d.department_name, b.record_type, b.function_description,
           b.be_2025_26,
           ROW_NUMBER() OVER (
               PARTITION BY b.dept_code, b.record_type
               ORDER BY b.be_2025_26 DESC NULLS LAST, b.function_description
           ) AS line_rank
    FROM dim_nagpur_budget b
    JOIN dim_nagpur_department d USING (dept_code)
)
SELECT department_name, record_type, line_rank, function_description, be_2025_26
FROM ranked_lines
WHERE line_rank <= 3
ORDER BY department_name, record_type, line_rank;

-- 14. Data-quality summary: missing detailed codes and missing budget amounts.
SELECT
    COUNT(*) AS total_budget_lines,
    COUNT(*) FILTER (WHERE detailed_code IS NULL) AS missing_detailed_code,
    COUNT(*) FILTER (WHERE be_2024_25 IS NULL) AS missing_2024_25_be,
    COUNT(*) FILTER (WHERE re_2024_25 IS NULL) AS missing_2024_25_re,
    COUNT(*) FILTER (WHERE be_2025_26 IS NULL) AS missing_2025_26_be
FROM dim_nagpur_budget;

-- 15. Department mapping validation: budget department codes without a matching name.
SELECT DISTINCT b.dept_code
FROM dim_nagpur_budget b
LEFT JOIN dim_nagpur_department d USING (dept_code)
WHERE d.dept_code IS NULL
ORDER BY b.dept_code;
