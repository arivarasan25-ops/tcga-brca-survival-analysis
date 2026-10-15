
-- 1. Preview key clinical fields.
SELECT
    patient_id,
    age,
    sex,
    ajcc_pathologic_tumor_stage,
    ajcc_tumor_pathologic_pt,
    ajcc_nodes_pathologic_pn,
    ajcc_metastasis_pathologic_pm,
    os_status,
    os_months,
    dfs_status,
    dfs_months
FROM staging.clinical_patient
LIMIT 10;

-- 2. Summarize age after validating numeric values.
WITH valid_ages AS (
    SELECT TRIM(age)::NUMERIC AS age_years
    FROM staging.clinical_patient
    WHERE TRIM(age) ~ '^[0-9]+(\.[0-9]+)?$'
)
SELECT
    COUNT(*) AS records_with_valid_age,
    MIN(age_years) AS youngest_age,
    MAX(age_years) AS oldest_age,
    ROUND(AVG(age_years), 1) AS average_age,
    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY age_years)::NUMERIC,
        1
    ) AS median_age
FROM valid_ages;

-- 3. Explore recorded sex values.
SELECT
    COALESCE(NULLIF(TRIM(sex), ''), '[Blank]') AS sex_category,
    COUNT(*) AS patient_count,
    ROUND(
        100.0 * COUNT(*) /
        NULLIF((SELECT COUNT(*) FROM staging.clinical_patient), 0),
        2
    ) AS percentage_of_all_records
FROM staging.clinical_patient
GROUP BY 1
ORDER BY patient_count DESC;

-- 4. Explore exact recorded tumor-stage categories.
SELECT
    COALESCE(
        NULLIF(TRIM(ajcc_pathologic_tumor_stage), ''),
        '[Blank]'
    ) AS cancer_stage,
    COUNT(*) AS patient_count
FROM staging.clinical_patient
GROUP BY 1
ORDER BY patient_count DESC;

-- 5. Explore T and N categories.
SELECT
    'T' AS category_type,
    COALESCE(NULLIF(TRIM(ajcc_tumor_pathologic_pt), ''), '[Blank]')
        AS category,
    COUNT(*) AS patient_count
FROM staging.clinical_patient
GROUP BY 1, 2

UNION ALL

SELECT
    'N' AS category_type,
    COALESCE(NULLIF(TRIM(ajcc_nodes_pathologic_pn), ''), '[Blank]')
        AS category,
    COUNT(*) AS patient_count
FROM staging.clinical_patient
GROUP BY 1, 2

ORDER BY category_type, patient_count DESC;

-- 6. Check completeness of T and N categories.
SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(ajcc_tumor_pathologic_pt), '') IS NOT NULL
    ) AS records_with_t_category,
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(ajcc_nodes_pathologic_pn), '') IS NOT NULL
    ) AS records_with_n_category,
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(ajcc_metastasis_pathologic_pm), '') IS NOT NULL
    ) AS records_with_m_category
FROM staging.clinical_patient;

-- 7. Inspect records with unclassified or unavailable stage values.
SELECT
    patient_id,
    ajcc_pathologic_tumor_stage,
    ajcc_tumor_pathologic_pt,
    ajcc_nodes_pathologic_pn,
    ajcc_metastasis_pathologic_pm,
    os_status,
    os_months
FROM staging.clinical_patient
WHERE LOWER(TRIM(ajcc_pathologic_tumor_stage))
      IN ('[not available]', '[discrepancy]', 'stage x')
   OR NULLIF(TRIM(ajcc_pathologic_tumor_stage), '') IS NULL
ORDER BY ajcc_pathologic_tumor_stage, patient_id;
