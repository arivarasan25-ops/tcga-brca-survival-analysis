
-- 1. Overall-survival time summary by event status.
SELECT
    event,
    CASE
        WHEN event = 1 THEN 'Deceased'
        WHEN event = 0 THEN 'Living / censored'
        ELSE 'Unknown status'
    END AS vital_status,
    COUNT(*) AS total_records,
    COUNT(os_months) AS records_with_valid_time,
    ROUND(AVG(os_months), 2) AS mean_months,
    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY os_months)::NUMERIC,
        2
    ) AS median_months,
    MIN(os_months) AS minimum_months,
    MAX(os_months) AS maximum_months
FROM staging.brca_survival_clean
GROUP BY event
ORDER BY event NULLS LAST;

-- 2. Define the eligible overall-survival cohort.
SELECT
    COUNT(*) AS all_source_records,
    COUNT(*) FILTER (
        WHERE os_months IS NOT NULL
          AND event IN (0, 1)
    ) AS eligible_for_km,
    COUNT(*) FILTER (
        WHERE event = 1
          AND os_months IS NULL
    ) AS deceased_missing_time,
    COUNT(*) FILTER (
        WHERE event = 0
          AND os_months IS NULL
    ) AS living_missing_time
FROM staging.brca_survival_clean;

-- 3. Inspect the analysis dataset.
SELECT
    patient_id,
    tumor_stage,
    event,
    os_months
FROM staging.brca_survival_clean
WHERE os_months IS NOT NULL
  AND event IN (0, 1)
ORDER BY os_months, patient_id;
