-- ============================================================
-- Query: Two-dimensional segment analysis (Contract × Internet)
-- ============================================================
-- Business question:
--   Which combination of contract type and internet service
--   represents the highest concentration of at-risk revenue?
--   This is the core question for designing a targeted
--   retention campaign — broad efforts waste budget on
--   customers who weren't going to churn anyway.
--
-- Technique used:
--   GROUP BY across two dimensions, conditional aggregation,
--   and a window function (SUM OVER) to compute each segment's
--   share of total churn revenue without a subquery.
-- ============================================================

WITH segment_metrics AS (
    SELECT
        sub.contract_type,
        s.internet_service,
        COUNT(*)                                          AS customers,
        SUM(CASE WHEN cs.churned THEN 1 ELSE 0 END)       AS churned,
        ROUND(
            100.0 * SUM(CASE WHEN cs.churned THEN 1 ELSE 0 END) / COUNT(*),
            1
        )                                                 AS churn_rate_pct,
        ROUND(AVG(b.monthly_charges), 2)                  AS avg_monthly_charges,
        ROUND(
            SUM(CASE WHEN cs.churned THEN b.monthly_charges ELSE 0 END),
            0
        )                                                 AS monthly_revenue_lost,
        ROUND(
            SUM(CASE WHEN cs.churned THEN b.monthly_charges ELSE 0 END) * 12,
            0
        )                                                 AS annual_revenue_lost
    FROM   subscriptions sub
    JOIN   services      s   ON sub.customer_id = s.customer_id
    JOIN   billing       b   ON sub.customer_id = b.customer_id
    JOIN   churn_status  cs  ON sub.customer_id = cs.customer_id
    GROUP BY sub.contract_type, s.internet_service
)

SELECT
    contract_type,
    internet_service,
    customers,
    churned,
    churn_rate_pct,
    avg_monthly_charges,
    annual_revenue_lost,
    ROUND(
        100.0 * annual_revenue_lost / SUM(annual_revenue_lost) OVER (),
        1
    ) AS pct_of_total_churn_revenue
FROM       segment_metrics
ORDER BY   annual_revenue_lost DESC;