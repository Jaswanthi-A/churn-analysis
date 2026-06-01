-- ============================================================
-- Query: Rules-based customer churn risk score
-- ============================================================
-- Business question:
--   Without training a machine learning model, can we score
--   each current customer on their likelihood of churning,
--   using only the patterns we've discovered? Yes — and this
--   SQL-native scorecard becomes the baseline that the ML
--   model in Phase 4 must beat.
--
--   The score (0-100) is built by assigning points for each
--   known risk factor: contract type, internet service,
--   tenure, payment method, and add-on services missing.
--
-- Technique used:
--   Multiple CASE WHEN expressions inside a single SELECT
--   composed into a weighted total. Then bucket the score
--   into actionable risk tiers (Low / Medium / High / Critical).
-- ============================================================

WITH risk_scoring AS (
    SELECT
        c.customer_id,
        sub.contract_type,
        s.internet_service,
        sub.tenure_months,
        sub.payment_method,
        b.monthly_charges,
        cs.churned,

        -- Contract type: biggest single predictor
        CASE
            WHEN sub.contract_type = 'Month-to-month' THEN 35
            WHEN sub.contract_type = 'One year'       THEN 15
            ELSE 0
        END AS pts_contract,

        -- Internet service: fiber is a major risk factor
        CASE
            WHEN s.internet_service = 'Fiber optic' THEN 20
            WHEN s.internet_service = 'DSL'         THEN 5
            ELSE 0
        END AS pts_internet,

        -- Tenure: first 12 months are danger zone
        CASE
            WHEN sub.tenure_months <= 6  THEN 25
            WHEN sub.tenure_months <= 12 THEN 15
            WHEN sub.tenure_months <= 24 THEN 5
            ELSE 0
        END AS pts_tenure,

        -- Payment method: electronic check correlates with churn
        CASE
            WHEN sub.payment_method = 'Electronic check' THEN 10
            ELSE 0
        END AS pts_payment,

        -- Missing protective services (no online security or tech support)
        CASE
            WHEN s.online_security = 'No' AND s.tech_support = 'No' THEN 10
            WHEN s.online_security = 'No' OR  s.tech_support = 'No' THEN 5
            ELSE 0
        END AS pts_no_protection

    FROM       customers     c
    JOIN       subscriptions sub ON c.customer_id = sub.customer_id
    JOIN       services      s   ON c.customer_id = s.customer_id
    JOIN       billing       b   ON c.customer_id = b.customer_id
    JOIN       churn_status  cs  ON c.customer_id = cs.customer_id
),

scored AS (
    SELECT
        *,
        (pts_contract + pts_internet + pts_tenure + pts_payment + pts_no_protection)
            AS risk_score,

        CASE
            WHEN (pts_contract + pts_internet + pts_tenure + pts_payment + pts_no_protection) >= 70 THEN 'Critical'
            WHEN (pts_contract + pts_internet + pts_tenure + pts_payment + pts_no_protection) >= 50 THEN 'High'
            WHEN (pts_contract + pts_internet + pts_tenure + pts_payment + pts_no_protection) >= 25 THEN 'Medium'
            ELSE 'Low'
        END AS risk_tier
    FROM risk_scoring
)

-- Aggregate view: how well does our SQL-only scorecard separate churners?
SELECT
    risk_tier,
    COUNT(*)                                                  AS customers,
    SUM(CASE WHEN churned THEN 1 ELSE 0 END)                  AS actual_churners,
    ROUND(
        100.0 * SUM(CASE WHEN churned THEN 1 ELSE 0 END) / COUNT(*),
        1
    )                                                         AS actual_churn_rate_pct,
    ROUND(AVG(risk_score), 1)                                 AS avg_risk_score,
    ROUND(SUM(monthly_charges), 0)                            AS monthly_revenue_in_tier,
    ROUND(
        SUM(CASE WHEN churned THEN monthly_charges ELSE 0 END) * 12,
        0
    )                                                         AS annualized_revenue_at_risk
FROM       scored
GROUP BY   risk_tier
ORDER BY
    CASE risk_tier
        WHEN 'Critical' THEN 1
        WHEN 'High'     THEN 2
        WHEN 'Medium'   THEN 3
        ELSE 4
    END;