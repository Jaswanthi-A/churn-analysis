-- ============================================================
-- Query: Cohort retention curve by tenure
-- ============================================================
-- Business question:
--   What does the retention curve look like across the customer
--   lifecycle? At each tenure milestone, what % of customers
--   are still active, and where does retention drop the most?
--   This identifies the intervention windows that matter.
--
-- Technique used:
--   - Tenure bucketed into 6-month cohorts
--   - SUM(...) FILTER (WHERE ...) for cleaner conditional aggregation
--   - LAG() window function to compute month-over-month drop-off
--   - CUMULATIVE retention as a survival-curve approximation
-- ============================================================

WITH cohorts AS (
    SELECT
        CASE
            WHEN sub.tenure_months <= 6  THEN '01: 0-6 months'
            WHEN sub.tenure_months <= 12 THEN '02: 7-12 months'
            WHEN sub.tenure_months <= 18 THEN '03: 13-18 months'
            WHEN sub.tenure_months <= 24 THEN '04: 19-24 months'
            WHEN sub.tenure_months <= 36 THEN '05: 25-36 months'
            WHEN sub.tenure_months <= 48 THEN '06: 37-48 months'
            WHEN sub.tenure_months <= 60 THEN '07: 49-60 months'
            ELSE                              '08: 61+ months'
        END AS cohort,
        sub.tenure_months,
        cs.churned,
        b.monthly_charges
    FROM   subscriptions sub
    JOIN   billing       b   ON sub.customer_id = b.customer_id
    JOIN   churn_status  cs  ON sub.customer_id = cs.customer_id
),

cohort_summary AS (
    SELECT
        cohort,
        COUNT(*)                                          AS customers,
        SUM(1) FILTER (WHERE NOT churned)                 AS retained,
        SUM(1) FILTER (WHERE churned)                     AS churned,
        ROUND(
            100.0 * SUM(1) FILTER (WHERE NOT churned) / COUNT(*),
            1
        )                                                 AS retention_rate_pct,
        ROUND(
            100.0 * SUM(1) FILTER (WHERE churned) / COUNT(*),
            1
        )                                                 AS churn_rate_pct,
        ROUND(AVG(monthly_charges), 2)                    AS avg_charges
    FROM     cohorts
    GROUP BY cohort
)

SELECT
    cohort,
    customers,
    retained,
    churned,
    retention_rate_pct,
    churn_rate_pct,
    avg_charges,

    -- Period-over-period change: how much does retention improve
    -- as customers move from one cohort to the next?
    retention_rate_pct - LAG(retention_rate_pct) OVER (ORDER BY cohort)
        AS retention_pp_change,

    -- Rolling: where in the lifecycle does retention "stabilize"?
    -- A flattening retention curve means customers have settled in.
    CASE
        WHEN ABS(retention_rate_pct - LAG(retention_rate_pct) OVER (ORDER BY cohort)) < 3
        THEN 'STABLE'
        ELSE 'CHANGING'
    END AS retention_trend

FROM     cohort_summary
ORDER BY cohort;