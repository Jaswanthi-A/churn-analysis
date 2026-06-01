-- ============================================================
-- Query: Churn rate by tenure bucket
-- ============================================================
-- Business question:
--   Customer tenure ranges from 0 to 72 months. To understand
--   when in the customer lifecycle churn happens, we bucket
--   tenure into meaningful ranges (first 6 months, 7-12, etc.)
--   and compute churn rate within each.
--
-- Technique used:
--   CASE WHEN to bucket a continuous numeric column into
--   discrete categories, then GROUP BY the derived column.
--   ORDER BY uses MIN(tenure_months) so buckets appear in
--   chronological order (instead of alphabetically).
-- ============================================================

WITH bucketed AS (
    SELECT
        sub.customer_id,
        sub.tenure_months,
        CASE
            WHEN sub.tenure_months <= 6  THEN '0-6 months'
            WHEN sub.tenure_months <= 12 THEN '7-12 months'
            WHEN sub.tenure_months <= 24 THEN '13-24 months'
            WHEN sub.tenure_months <= 48 THEN '25-48 months'
            ELSE                              '49+ months'
        END AS tenure_bucket,
        cs.churned,
        b.monthly_charges
    FROM   subscriptions sub
    JOIN   billing       b  ON sub.customer_id = b.customer_id
    JOIN   churn_status  cs ON sub.customer_id = cs.customer_id
)

SELECT
    tenure_bucket,
    COUNT(*)                                              AS customers,
    SUM(CASE WHEN churned THEN 1 ELSE 0 END)              AS churned_customers,
    ROUND(
        100.0 * SUM(CASE WHEN churned THEN 1 ELSE 0 END) / COUNT(*),
        1
    )                                                     AS churn_rate_pct,
    ROUND(AVG(monthly_charges), 2)                        AS avg_monthly_charges,
    ROUND(
        SUM(CASE WHEN churned THEN monthly_charges ELSE 0 END) * 12,
        0
    )                                                     AS annual_revenue_lost
FROM       bucketed
GROUP BY   tenure_bucket
ORDER BY   MIN(tenure_months);