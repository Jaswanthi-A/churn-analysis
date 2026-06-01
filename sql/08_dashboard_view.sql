-- ============================================================
-- View: customer_360
-- ============================================================
-- A single denormalized view combining all customer attributes
-- for use by the Power BI dashboard. This isolates the dashboard
-- from schema changes — if we add more tables later, only this
-- view needs updating.
--
-- Includes:
--   - All demographic, subscription, service, and billing fields
--   - The churn label
--   - Derived fields useful for dashboard slicing:
--       * tenure_bucket
--       * risk_tier (the rules-based score from query #7)
--       * monthly revenue at risk
-- ============================================================

DROP VIEW IF EXISTS customer_360;

CREATE VIEW customer_360 AS
WITH risk_scoring AS (
    SELECT
        c.customer_id,

        -- Risk score components (mirrors 07_customer_risk_score.sql)
        CASE
            WHEN sub.contract_type = 'Month-to-month' THEN 35
            WHEN sub.contract_type = 'One year'       THEN 15
            ELSE 0
        END
        + CASE
            WHEN s.internet_service = 'Fiber optic' THEN 20
            WHEN s.internet_service = 'DSL'         THEN 5
            ELSE 0
        END
        + CASE
            WHEN sub.tenure_months <= 6  THEN 25
            WHEN sub.tenure_months <= 12 THEN 15
            WHEN sub.tenure_months <= 24 THEN 5
            ELSE 0
        END
        + CASE
            WHEN sub.payment_method = 'Electronic check' THEN 10
            ELSE 0
        END
        + CASE
            WHEN s.online_security = 'No' AND s.tech_support = 'No' THEN 10
            WHEN s.online_security = 'No' OR  s.tech_support = 'No' THEN 5
            ELSE 0
        END AS risk_score

    FROM   customers c
    JOIN   subscriptions sub ON c.customer_id = sub.customer_id
    JOIN   services      s   ON c.customer_id = s.customer_id
)

SELECT
    c.customer_id,

    -- Demographics
    c.gender,
    c.senior_citizen,
    c.has_partner,
    c.has_dependents,

    -- Subscription
    sub.tenure_months,
    CASE
        WHEN sub.tenure_months <= 6  THEN '01: 0-6 months'
        WHEN sub.tenure_months <= 12 THEN '02: 7-12 months'
        WHEN sub.tenure_months <= 24 THEN '03: 13-24 months'
        WHEN sub.tenure_months <= 48 THEN '04: 25-48 months'
        ELSE                              '05: 49+ months'
    END AS tenure_bucket,
    sub.contract_type,
    sub.paperless_billing,
    sub.payment_method,

    -- Services
    s.phone_service,
    s.multiple_lines,
    s.internet_service,
    s.online_security,
    s.online_backup,
    s.device_protection,
    s.tech_support,
    s.streaming_tv,
    s.streaming_movies,

    -- Billing
    b.monthly_charges,
    b.total_charges,

    -- Churn label
    cs.churned,

    -- Risk score and tier
    rs.risk_score,
    CASE
        WHEN rs.risk_score >= 70 THEN '1: Critical'
        WHEN rs.risk_score >= 50 THEN '2: High'
        WHEN rs.risk_score >= 25 THEN '3: Medium'
        ELSE                          '4: Low'
    END AS risk_tier,

    -- Monthly revenue at risk: only relevant for customers who haven't churned yet
    CASE
        WHEN cs.churned = FALSE THEN b.monthly_charges
        ELSE 0
    END AS monthly_revenue_at_risk_if_churned

FROM       customers     c
JOIN       subscriptions sub ON c.customer_id = sub.customer_id
JOIN       services      s   ON c.customer_id = s.customer_id
JOIN       billing       b   ON c.customer_id = b.customer_id
JOIN       churn_status  cs  ON c.customer_id = cs.customer_id
JOIN       risk_scoring  rs  ON c.customer_id = rs.customer_id;