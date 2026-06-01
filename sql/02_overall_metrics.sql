-- ============================================================
-- Query: Overall churn metrics
-- ============================================================
-- Business question:
--   What are the company's headline churn numbers — how many
--   customers do we have, what % churn, how much monthly
--   revenue do they represent, and how does that compare to
--   the customers who stay?
--
-- Technique used:
--   Conditional aggregation with CASE WHEN inside aggregate
--   functions — a common pattern for computing rates and
--   slicing metrics by category in a single pass over the
--   data. More efficient than multiple subqueries.
-- ============================================================

SELECT
    -- Customer counts
    COUNT(*)                                              AS total_customers,
    SUM(CASE WHEN cs.churned THEN 1 ELSE 0 END)           AS churned_customers,
    SUM(CASE WHEN NOT cs.churned THEN 1 ELSE 0 END)       AS retained_customers,

    -- Churn rate as a percentage
    ROUND(
        100.0 * SUM(CASE WHEN cs.churned THEN 1 ELSE 0 END) / COUNT(*),
        1
    )                                                     AS churn_rate_pct,

    -- Revenue metrics
    ROUND(SUM(b.monthly_charges), 0)                      AS total_monthly_revenue,
    ROUND(
        SUM(CASE WHEN cs.churned THEN b.monthly_charges ELSE 0 END),
        0
    )                                                     AS revenue_lost_to_churn,
    ROUND(
        SUM(CASE WHEN cs.churned THEN b.monthly_charges ELSE 0 END) * 12,
        0
    )                                                     AS annualized_churn_impact,

    -- ARPU comparison: are churners high-value or low-value?
    ROUND(
        AVG(CASE WHEN cs.churned THEN b.monthly_charges END),
        2
    )                                                     AS avg_charges_churned,
    ROUND(
        AVG(CASE WHEN NOT cs.churned THEN b.monthly_charges END),
        2
    )                                                     AS avg_charges_retained

FROM   customers       c
JOIN   billing         b  ON c.customer_id = b.customer_id
JOIN   churn_status    cs ON c.customer_id = cs.customer_id;