
-- Create a cleaned analysis view.
-- event = 1: death recorded
-- event = 0: living/censored
-- Invalid or unavailable survival times become NULL.

CREATE OR REPLACE VIEW staging.brca_survival_clean AS
SELECT
    TRIM(patient_id) AS patient_id,
    TRIM(ajcc_pathologic_tumor_stage) AS tumor_stage,

    CASE
        WHEN TRIM(os_status) = '1:DECEASED' THEN 1
        WHEN TRIM(os_status) = '0:LIVING' THEN 0
        ELSE NULL
    END AS event,

    CASE
        WHEN TRIM(os_months) ~ '^[0-9]+(\.[0-9]+)?$'
        THEN TRIM(os_months)::NUMERIC
        ELSE NULL
    END AS os_months,

    CASE
        WHEN TRIM(os_status) IN ('0:LIVING', '1:DECEASED')
        THEN TRUE
        ELSE FALSE
    END AS valid_status,

    CASE
        WHEN TRIM(os_months) ~ '^[0-9]+(\.[0-9]+)?$'
        THEN TRUE
        ELSE FALSE
    END AS valid_survival_time

FROM staging.clinical_patient;

-- Verify the cleaned view.
SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (WHERE event = 0) AS living_records,
    COUNT(*) FILTER (WHERE event = 1) AS deceased_records,
    COUNT(*) FILTER (WHERE os_months IS NOT NULL)
        AS records_with_survival_time,
    COUNT(*) FILTER (
        WHERE event = 1 AND os_months IS NULL
    ) AS deceased_without_survival_time,
    COUNT(*) FILTER (
        WHERE event IS NOT NULL AND os_months IS NOT NULL
    ) AS eligible_for_survival_analysis
FROM staging.brca_survival_clean;

-- Inspect the cleaned fields.
SELECT patient_id, tumor_stage, event, os_months
FROM staging.brca_survival_clean
ORDER BY patient_id
LIMIT 20;
