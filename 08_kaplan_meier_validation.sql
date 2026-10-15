
-- Check 1: Confirm the analysis cohort.
SELECT
    COUNT(*) AS eligible_records,
    COUNT(*) FILTER (WHERE event = 0) AS censored_records,
    COUNT(*) FILTER (WHERE event = 1) AS death_records,
    MIN(os_months) AS minimum_time_months,
    MAX(os_months) AS maximum_time_months,
    COUNT(*) FILTER (WHERE os_months < 0) AS negative_times
FROM staging.brca_survival_clean
WHERE os_months IS NOT NULL
  AND event IN (0, 1);


-- Check 2: Recalculate the estimates for validation.
WITH patient_data AS (
    SELECT os_months, event
    FROM staging.brca_survival_clean
    WHERE os_months IS NOT NULL
      AND event IN (0, 1)
),
death_times AS (
    SELECT
        os_months AS time_months,
        COUNT(*) FILTER (WHERE event = 1) AS deaths
    FROM patient_data
    GROUP BY os_months
    HAVING COUNT(*) FILTER (WHERE event = 1) > 0
),
risk_table AS (
    SELECT
        d.time_months,
        d.deaths,
        COUNT(p.os_months) AS at_risk
    FROM death_times d
    JOIN patient_data p
      ON p.os_months >= d.time_months
    GROUP BY d.time_months, d.deaths
),
factors AS (
    SELECT
        *,
        1.0 - deaths::NUMERIC / NULLIF(at_risk, 0)
            AS survival_factor
    FROM risk_table
),
estimates AS (
    SELECT
        *,
        SUM(
            CASE
                WHEN survival_factor > 0
                THEN LN(survival_factor::DOUBLE PRECISION)
                ELSE 0
            END
        ) OVER (
            ORDER BY time_months
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_log,
        SUM(
            CASE WHEN survival_factor = 0 THEN 1 ELSE 0 END
        ) OVER (
            ORDER BY time_months
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS zero_factors
    FROM factors
),
km AS (
    SELECT
        *,
        CASE
            WHEN zero_factors > 0 THEN 0.0
            ELSE EXP(cumulative_log)
        END AS survival_probability
    FROM estimates
),
checked AS (
    SELECT
        *,
        LAG(survival_probability) OVER (
            ORDER BY time_months
        ) AS previous_survival_probability
    FROM km
)
SELECT
    COUNT(*) AS death_time_rows,
    SUM(deaths) AS total_deaths_counted,
    COUNT(*) FILTER (
        WHERE at_risk < deaths OR at_risk <= 0
    ) AS invalid_risk_counts,
    COUNT(*) FILTER (
        WHERE survival_probability < 0
           OR survival_probability > 1
           OR survival_probability IS NULL
    ) AS invalid_survival_probabilities,
    COUNT(*) FILTER (
        WHERE previous_survival_probability IS NOT NULL
          AND survival_probability >
              previous_survival_probability + 0.000000001
    ) AS upward_steps
FROM checked;


-- Check 3: Inspect individual KM steps.
-- Use this to manually verify the early calculations.
WITH patient_data AS (
    SELECT os_months, event
    FROM staging.brca_survival_clean
    WHERE os_months IS NOT NULL
      AND event IN (0, 1)
),
death_times AS (
    SELECT
        os_months AS time_months,
        COUNT(*) FILTER (WHERE event = 1) AS deaths
    FROM patient_data
    GROUP BY os_months
    HAVING COUNT(*) FILTER (WHERE event = 1) > 0
),
risk_table AS (
    SELECT
        d.time_months,
        d.deaths,
        COUNT(p.os_months) AS at_risk
    FROM death_times d
    JOIN patient_data p
      ON p.os_months >= d.time_months
    GROUP BY d.time_months, d.deaths
),
factors AS (
    SELECT
        *,
        1.0 - deaths::NUMERIC / NULLIF(at_risk, 0)
            AS survival_factor
    FROM risk_table
)
SELECT
    time_months,
    deaths,
    at_risk,
    survival_factor
FROM factors
ORDER BY time_months
LIMIT 10;
