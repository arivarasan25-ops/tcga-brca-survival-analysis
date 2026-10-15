
-- Kaplan-Meier overall-survival estimates.
-- Run after creating staging.brca_survival_clean.

WITH patient_data AS (
    SELECT
        patient_id,
        os_months,
        event
    FROM staging.brca_survival_clean
    WHERE os_months IS NOT NULL
      AND event IN (0, 1)
),

-- Keep times at which at least one death occurred.
death_times AS (
    SELECT
        os_months AS time_months,
        COUNT(*) FILTER (WHERE event = 1) AS deaths
    FROM patient_data
    GROUP BY os_months
    HAVING COUNT(*) FILTER (WHERE event = 1) > 0
),

-- Count observations still at risk at each death time.
risk_table AS (
    SELECT
        d.time_months,
        d.deaths,
        COUNT(p.patient_id) AS at_risk
    FROM death_times d
    JOIN patient_data p
      ON p.os_months >= d.time_months
    GROUP BY d.time_months, d.deaths
),

-- Calculate each Kaplan-Meier survival factor.
factors AS (
    SELECT
        time_months,
        deaths,
        at_risk,
        1.0 - deaths::NUMERIC / NULLIF(at_risk, 0)
            AS survival_factor
    FROM risk_table
),

-- Accumulate logarithms to calculate the product.
-- Handle a zero survival factor safely.
cumulative AS (
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
            CASE
                WHEN survival_factor = 0 THEN 1
                ELSE 0
            END
        ) OVER (
            ORDER BY time_months
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS zero_factors
    FROM factors
)

SELECT
    time_months,
    deaths,
    at_risk,
    CASE
        WHEN zero_factors > 0 THEN 0.0
        ELSE EXP(cumulative_log)
    END AS survival_probability
FROM cumulative
ORDER BY time_months;
