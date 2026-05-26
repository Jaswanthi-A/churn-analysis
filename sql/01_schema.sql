-- ============================================================
-- Telco Customer Churn Database Schema
-- ============================================================
-- This script creates a normalized schema for the Telco churn 
-- dataset. The flat source CSV is split into 5 related tables 
-- linked by customer_id, mirroring how a real telecom would 
-- structure its data warehouse.
-- ============================================================

-- Drop existing tables (in dependency order) to allow re-running
DROP TABLE IF EXISTS churn_status CASCADE;
DROP TABLE IF EXISTS billing CASCADE;
DROP TABLE IF EXISTS services CASCADE;
DROP TABLE IF EXISTS subscriptions CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- ============================================================
-- customers: demographic information
-- ============================================================
CREATE TABLE customers (
    customer_id      VARCHAR(20) PRIMARY KEY,
    gender           VARCHAR(10) NOT NULL,
    senior_citizen   BOOLEAN     NOT NULL,
    has_partner      BOOLEAN     NOT NULL,
    has_dependents   BOOLEAN     NOT NULL
);

-- ============================================================
-- subscriptions: contract and account-level details
-- ============================================================
CREATE TABLE subscriptions (
    customer_id        VARCHAR(20) PRIMARY KEY REFERENCES customers(customer_id),
    tenure_months      INTEGER     NOT NULL CHECK (tenure_months >= 0),
    contract_type      VARCHAR(20) NOT NULL,
    paperless_billing  BOOLEAN     NOT NULL,
    payment_method     VARCHAR(40) NOT NULL
);

-- ============================================================
-- services: which products/services each customer has
-- ============================================================
CREATE TABLE services (
    customer_id          VARCHAR(20) PRIMARY KEY REFERENCES customers(customer_id),
    phone_service        BOOLEAN     NOT NULL,
    multiple_lines       VARCHAR(20),  -- "Yes", "No", or "No phone service"
    internet_service     VARCHAR(20) NOT NULL,
    online_security      VARCHAR(20),
    online_backup        VARCHAR(20),
    device_protection    VARCHAR(20),
    tech_support         VARCHAR(20),
    streaming_tv         VARCHAR(20),
    streaming_movies     VARCHAR(20)
);

-- ============================================================
-- billing: revenue per customer
-- ============================================================
CREATE TABLE billing (
    customer_id      VARCHAR(20)  PRIMARY KEY REFERENCES customers(customer_id),
    monthly_charges  NUMERIC(8,2) NOT NULL CHECK (monthly_charges >= 0),
    total_charges    NUMERIC(10,2) NOT NULL CHECK (total_charges >= 0)
);

-- ============================================================
-- churn_status: the target variable
-- ============================================================
CREATE TABLE churn_status (
    customer_id  VARCHAR(20) PRIMARY KEY REFERENCES customers(customer_id),
    churned      BOOLEAN     NOT NULL
);

-- ============================================================
-- Indexes to speed up common analytical queries
-- ============================================================
CREATE INDEX idx_subscriptions_contract ON subscriptions(contract_type);
CREATE INDEX idx_services_internet      ON services(internet_service);
CREATE INDEX idx_churn_status_churned   ON churn_status(churned);