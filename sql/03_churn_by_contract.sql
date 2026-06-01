-- ============================================================
-- Query: Churn rate and revenue impact by contract type
-- ============================================================
-- Business question:
--   How does churn vary by contract type, and what does that
--   gap mean in revenue terms? Contract type is the strongest
--   single predictor of churn in this dataset.
--
-- Technique used:
--   GROUP BY with conditional aggregation, ratio calculations,
--   and ORDER BY on a derived metric. Demonstrates how to
--   produce a "category breakdown" report — one of the most
--   common analytical patterns in business reporting.
-- ============================================================

SELECT
    sub.contract_type,

    -- Volume metrics
    COUNT(*)                                              AS total_customers,
    SUM(CASE WHEN cs.churned THEN 1 ELSE 0 END)           AS churned_customers,

    -- Churn rate within this segment
    ROUND(
        100.0 * SUM(CASE WHEN cs.churned THEN 1 ELSE 0 END) / COUNT(*),
        1
    )                                                     AS churn_rate_pct,

    -- Revenue lost from this segment, monthly + annualized
    ROUND(
        SUM(CASE WHEN cs.churned THEN b.monthly_charges ELSE 0 END),
        0
    )                                                     AS monthly_revenue_lost,
    ROUND(
        SUM(CASE WHEN cs.churned THEN b.monthly_charges ELSE 0 END) * 12,
        0
    )                                                     AS annual_revenue_lost,

    -- What share of all churn revenue does this segment represent?
    ROUND(
        100.0 * SUM(CASE WHEN cs.churned THEN b.monthly_charges ELSE 0 END)
              / (SELECT SUM(CASE WHEN cs2.churned THEN b2.monthly_charges ELSE 0 END)
                 FROM billing b2 JOIN churn_status cs2 ON b2.customer_id = cs2.customer_id),
        1
    )                                                     AS pct_of_total_churn_revenue

FROM       subscriptions sub
JOIN       billing       b   ON sub.customer_id = b.customer_id
JOIN       churn_status  cs  ON sub.customer_id = cs.customer_id
GROUP BY   sub.contract_type
ORDER BY   churn_rate_pct DESC;