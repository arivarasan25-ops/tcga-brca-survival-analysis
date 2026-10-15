
-- Group detailed AJCC stage labels into broad stage groups.
WITH stage_data AS (
    SELECT
        CASE
            WHEN TRIM(ajcc_pathologic_tumor_stage)
                 IN ('Stage I', 'Stage IA', 'Stage IB')
                THEN 'Stage I'

            WHEN TRIM(ajcc_pathologic_tumor_stage)
                 IN ('Stage II', 'Stage IIA', 'Stage IIB')
                THEN 'Stage II'

            WHEN TRIM(ajcc_pathologic_tumor_stage)
                 IN ('Stage III', 'Stage IIIA', 'Stage IIIB', 'Stage IIIC')
                THEN 'Stage III'

            WHEN TRIM(ajcc_pathologic_tumor_stage) = 'Stage IV'
                THEN 'Stage IV'

            ELSE 'Unclassified'
        END AS stage_group,
        TRIM(os_status) AS os_status
    FROM staging.clinical_patient
)
SELECT
    stage_group,
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE os_status = '0:LIVING'
    ) AS living_records,
    COUNT(*) FILTER (
        WHERE os_status = '1:DECEASED'
    ) AS deceased_records,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE os_status = '1:DECEASED'
        ) /
        NULLIF(
            COUNT(*) FILTER (
                WHERE os_status IN ('0:LIVING', '1:DECEASED')
            ),
            0
        ),
        2
    ) AS deceased_percentage_among_known_status
FROM stage_data
GROUP BY stage_group
ORDER BY CASE stage_group
    WHEN 'Stage I' THEN 1
    WHEN 'Stage II' THEN 2
    WHEN 'Stage III' THEN 3
    WHEN 'Stage IV' THEN 4
    ELSE 5
END;
