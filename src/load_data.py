"""
ETL script: load the Telco churn CSV into the normalized PostgreSQL schema.

Reads:  data/raw/telco_churn_raw.csv
Writes: 5 tables in churn_db (customers, subscriptions, services, billing, churn_status)
"""

import os
import pandas as pd
from sqlalchemy import create_engine
from dotenv import load_dotenv

# ----------------------------------------------------------------------
# Load credentials from .env
# ----------------------------------------------------------------------
load_dotenv()

from urllib.parse import quote_plus

DB_USER = os.getenv("POSTGRES_USER")
DB_PASS = quote_plus(os.getenv("POSTGRES_PASSWORD"))  # URL-encode special chars
DB_HOST = os.getenv("POSTGRES_HOST")
DB_PORT = os.getenv("POSTGRES_PORT")
DB_NAME = os.getenv("POSTGRES_DB")

connection_string = f"postgresql+psycopg2://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
engine = create_engine(connection_string)

# ----------------------------------------------------------------------
# Helper: convert Yes/No strings to booleans
# ----------------------------------------------------------------------
def yes_no_to_bool(series: pd.Series) -> pd.Series:
    return series.map({"Yes": True, "No": False})


# ----------------------------------------------------------------------
# Extract: read raw CSV
# ----------------------------------------------------------------------
print("Reading source CSV...")
df = pd.read_csv("data/raw/telco_churn_raw.csv")
print(f"  {len(df):,} rows loaded")

# Fix the TotalCharges issue we found in EDA
df["TotalCharges"] = pd.to_numeric(df["TotalCharges"], errors="coerce").fillna(0)


# ----------------------------------------------------------------------
# Transform: split the flat dataframe into 5 normalized tables
# ----------------------------------------------------------------------
print("Transforming...")

customers = pd.DataFrame({
    "customer_id":    df["customerID"],
    "gender":         df["gender"],
    "senior_citizen": df["SeniorCitizen"].astype(bool),
    "has_partner":    yes_no_to_bool(df["Partner"]),
    "has_dependents": yes_no_to_bool(df["Dependents"]),
})

subscriptions = pd.DataFrame({
    "customer_id":       df["customerID"],
    "tenure_months":     df["tenure"],
    "contract_type":     df["Contract"],
    "paperless_billing": yes_no_to_bool(df["PaperlessBilling"]),
    "payment_method":    df["PaymentMethod"],
})

services = pd.DataFrame({
    "customer_id":       df["customerID"],
    "phone_service":     yes_no_to_bool(df["PhoneService"]),
    "multiple_lines":    df["MultipleLines"],
    "internet_service":  df["InternetService"],
    "online_security":   df["OnlineSecurity"],
    "online_backup":     df["OnlineBackup"],
    "device_protection": df["DeviceProtection"],
    "tech_support":      df["TechSupport"],
    "streaming_tv":      df["StreamingTV"],
    "streaming_movies":  df["StreamingMovies"],
})

billing = pd.DataFrame({
    "customer_id":     df["customerID"],
    "monthly_charges": df["MonthlyCharges"],
    "total_charges":   df["TotalCharges"],
})

churn_status = pd.DataFrame({
    "customer_id": df["customerID"],
    "churned":     yes_no_to_bool(df["Churn"]),
})


# ----------------------------------------------------------------------
# Load: write each table to PostgreSQL
# Insertion order matters because of foreign keys (customers first).
# ----------------------------------------------------------------------
print("Loading into PostgreSQL...")

tables = [
    ("customers",     customers),
    ("subscriptions", subscriptions),
    ("services",      services),
    ("billing",       billing),
    ("churn_status",  churn_status),
]

for name, frame in tables:
    frame.to_sql(name, engine, if_exists="append", index=False, method="multi")
    print(f"  {name:15} {len(frame):>6,} rows loaded")

print("\n✅ Load complete.")