
-- 1. Confirm that the staging table exists.
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'staging'
  AND table_name = 'clinical_patient';

-- 2. Inspect column names and data types.
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name = 'clinical_patient'
ORDER BY ordinal_position;

-- 3. Check total records.
SELECT COUNT(*) AS total_records
FROM staging.clinical_patient;

-- 4. Count columns.
SELECT COUNT(*) AS total_columns
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name = 'clinical_patient';

-- 5. Preview imported data.
SELECT *
FROM staging.clinical_patient
LIMIT 5;

-- 6. Check patient ID uniqueness and missing IDs.
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT NULLIF(TRIM(patient_id), ''))
        AS unique_nonblank_patient_ids,
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(patient_id), '') IS NULL
    ) AS missing_patient_ids,
    COUNT(*) - COUNT(DISTINCT NULLIF(TRIM(patient_id), ''))
        AS records_minus_unique_ids
FROM staging.clinical_patient;

-- 7. Check missing values in important fields.
SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(age), '') IS NULL
           OR LOWER(TRIM(age)) IN
              ('[not available]', '[not applicable]')
    ) AS missing_age,
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(sex), '') IS NULL
           OR LOWER(TRIM(sex)) IN
              ('[not available]', '[not applicable]')
    ) AS missing_sex,
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(os_status), '') IS NULL
           OR LOWER(TRIM(os_status)) IN
              ('[not available]', '[not applicable]')
    ) AS missing_os_status,
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(os_months), '') IS NULL
           OR LOWER(TRIM(os_months)) IN
              ('[not available]', '[not applicable]')
    ) AS missing_os_months
FROM staging.clinical_patient;

-- 8. Inspect overall-survival status values.
SELECT
    TRIM(os_status) AS os_status,
    COUNT(*) AS record_count
FROM staging.clinical_patient
GROUP BY TRIM(os_status)
ORDER BY record_count DESC;

-- 9. Validate overall-survival time values.
SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE TRIM(os_months) ~ '^[0-9]+(\.[0-9]+)?$'
    ) AS valid_numeric_times,
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(os_months), '') IS NULL
           OR LOWER(TRIM(os_months)) IN
              ('[not available]', '[not applicable]')
    ) AS missing_times,
    COUNT(*) FILTER (
        WHERE TRIM(os_months) ~ '^-?[0-9]+(\.[0-9]+)?$'
          AND TRIM(os_months)::NUMERIC < 0
    ) AS negative_times,
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(os_months), '') IS NOT NULL
          AND LOWER(TRIM(os_months)) NOT IN
              ('[not available]', '[not applicable]')
          AND TRIM(os_months) !~ '^-?[0-9]+(\.[0-9]+)?$'
    ) AS other_non_numeric_values
FROM staging.clinical_patient;

-- 10. Find deceased patients without a usable survival time.
SELECT patient_id, os_status, os_months
FROM staging.clinical_patient
WHERE TRIM(os_status) = '1:DECEASED'
  AND (
      NULLIF(TRIM(os_months), '') IS NULL
      OR TRIM(os_months) !~ '^[0-9]+(\.[0-9]+)?$'
  );

-- 11. Check for negative overall-survival times.
SELECT patient_id, os_status, os_months
FROM staging.clinical_patient
WHERE TRIM(os_months) ~ '^-?[0-9]+(\.[0-9]+)?$'
  AND TRIM(os_months)::NUMERIC < 0;
