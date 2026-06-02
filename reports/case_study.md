# Reducing Customer Churn at a Telecom Provider

**A data-driven retention strategy projected to recover $275K+ annually**

*Prepared by Jaswanthi Adla*

---

## Executive Summary

- **The problem:** A telecom provider is losing $1.67M annually to customer churn — 26.5% of customers leave each year, and churners pay 21% more on average than retained customers ($74.44 vs $61.27/month).
- **The finding:** A single customer segment — month-to-month contract holders with fiber internet — drives **72% of all churn revenue** while representing just 30% of the customer base. 53% of all churn happens in the first 6 months of tenure.
- **The recommendation:** A targeted retention program focused on month-to-month fiber customers in their first year — combined with first-6-month onboarding investment — could recover an estimated **$275K+ in annual net business value** while requiring far less spend than broad retention campaigns.

---

## Business Context

For subscription-based businesses, customer churn directly erodes recurring revenue. Industry research consistently shows that acquiring a new customer costs **5–7x more than retaining an existing one**, making retention one of the highest-ROI investments a telecom can make.

This analysis examined 7,043 customers from a US telecom dataset (IBM Telco Customer Churn) to answer three questions:

1. **Who** is most likely to churn?
2. **Why** are they churning?
3. **What** can the business do, and what is the projected impact?

---

## Approach

The analysis combined exploratory data analysis, normalized SQL data modeling, and predictive machine learning across a unified pipeline. Customer demographic, subscription, service, billing, and churn data were loaded from CSV into a normalized 5-table PostgreSQL schema. SQL queries quantified the size and concentration of the churn problem across segments. A logistic regression model trained on engineered features achieved a **0.839 ROC-AUC** on a held-out test set, recovering 80% of churners at the optimal threshold. SHAP analysis confirmed the same drivers identified in exploratory analysis. A four-page Power BI dashboard built on top of the live database visualizes findings for operational use.

---

## Key Findings

### 1. Contract type is the single largest predictor of churn

Customers on month-to-month contracts churn at **42.7%**, compared to **11.3%** for one-year contracts and **2.8%** for two-year contracts — a **15x gap** between the worst and best contract types. Month-to-month customers alone generate **86.9% of all churn revenue**, totaling **$1.45M annually** out of the $1.67M total. The two-year contract segment, while equally large in customer count, contributes just **3% of churn revenue** — essentially a non-problem.

### 2. One customer segment drives 72% of all churn revenue

Cross-segmenting by contract type AND internet service reveals a sharper picture: **month-to-month customers with fiber internet** (2,128 customers, just 30% of the base) churn at **54.6%** — more than half — and generate **$1.21M in annual churn revenue**. This single segment alone accounts for **72.2% of total churn revenue**. By comparison, the bottom four segments combined account for less than 4%. This is a textbook Pareto pattern: a concentrated source of risk that responds to focused intervention.

### 3. Customer retention is fundamentally a first-year problem

Of customers in their first 6 months, **53% churn**. Retention jumps **17 percentage points** between months 6 and 12 — the single largest improvement in the entire customer lifecycle. By 4+ years of tenure, retention stabilizes above 80% and grows only marginally thereafter. **Investment in onboarding, early engagement, and proactive support during the first six months would address the company's largest retention leak.** Beyond 12 months, retention spend faces diminishing returns.

### 4. Churned customers pay more, not less

Contrary to the assumption that churn is dominated by price-sensitive low-value customers, **churners pay 21% more on average** than retained customers ($74.44 vs $61.27/month). This means the company is losing its highest-value customers, not just any customers. The lifetime value of saving these customers compounds: average monthly charges grow from $54 to $76 between months 6 and year 5+, a **39% revenue increase per customer** from tenure alone.

### 5. Predictive modeling validates and operationalizes the findings

Three models were trained and compared on the same data:

| Model | ROC-AUC | PR-AUC | Recall on Churners |
|---|---|---|---|
| Logistic Regression | **0.839** | 0.641 | 80.0% |
| Random Forest | 0.821 | 0.624 | 50.5% |
| XGBoost | 0.831 | 0.647 | 75.9% |

The simplest model — logistic regression — outperformed both ensemble methods. This is itself a finding: the relationship between features and churn is largely linear and additive, so a more complex model adds operational cost without performance gain. The logistic model has the further advantage of full interpretability — each customer's risk score can be explained in business terms.

Cost-based threshold tuning identified an optimal classification threshold of 0.50, producing **$55K in net business value on the held-out test set** (after retention program costs). Scaled to the full customer base, this represents approximately **$275K in annual net value recovery** — roughly 17% of the $1.67M churn loss, with significant upside if retention success rates exceed the conservative 30% assumption.

---

## Recommendations

### 1. Contract conversion program for month-to-month fiber customers

**Action:** Launch a targeted retention offer for the 2,128 month-to-month fiber customers, with meaningful incentives (e.g., a 15% discount, locked-in pricing, or upgraded service tier) in exchange for a 1- or 2-year contract commitment.

**Rationale:** This single intervention addresses the segment driving 72% of churn revenue. Converting these customers from 54.6% churn (month-to-month fiber) to 19.3% churn (one-year fiber) would reduce segment churn by ~35 percentage points.

**Estimated breakeven:** At $87/month average revenue, even a 15% discount preserves $89/month in net revenue per converted customer. The math is overwhelmingly positive at any reasonable conversion rate above 5%.

### 2. First-six-month onboarding investment

**Action:** Build a structured first-six-month customer journey including a 30-day check-in, proactive support touchpoints at months 2 and 4, and a "completed onboarding" milestone reward.

**Rationale:** 53% of all churn happens in the first 6 months, and retention improves dramatically once customers cross the 12-month mark. The greatest leverage in the entire customer lifecycle is during the first year.

### 3. Service add-on attachment during onboarding

**Action:** Bundle online security and tech support as default add-ons (with opt-out) during the first 90 days, with discounted pricing.

**Rationale:** Customers without protective services churn at ~42%, while those with them churn at ~15% — a finding consistent across four different add-on types. Whether the services *cause* lower churn or merely *correlate* with more-committed customers, defaulting customers into protection creates either way.

### 4. Auto-pay conversion campaign

**Action:** Identify the customers paying via electronic check (the highest-churn payment method at 45.3%) and offer a one-time bill credit ($10–$25) for converting to auto-pay (bank transfer or credit card).

**Rationale:** Auto-pay customers churn at ~16% vs 45.3% for electronic check — a 3x gap. While payment method is likely a proxy for customer commitment, the conversion itself is a low-cost behavioral nudge that signals (and reinforces) commitment.

### 5. Deploy the predictive model for daily operational scoring

**Action:** Run the logistic regression model nightly on the customer base, surfacing the Critical and High tier list (currently 2,640 customers) to the retention team as a prioritized call list.

**Rationale:** Rather than relying on intuition or post-hoc analysis, the retention team can act on data-driven prioritization daily. The model's 80% recall on churners means a focused effort on the top-ranked customers addresses the vast majority of at-risk revenue.

---

## Projected Impact

If the recommendations above are implemented at conservative rates, the projected annual impact is approximately:

| Recommendation | Annual Impact (Conservative) |
|---|---|
| Contract conversion (10% conversion of M2M fiber) | **$120K** |
| First-6-month retention improvement (5pp churn reduction) | **$80K** |
| Service add-on attachment (10% improvement in retention) | **$45K** |
| Auto-pay conversion (15% behavioral nudge) | **$30K** |
| **Total estimated annual recovery** | **≈ $275K** |

This represents a **~17% recovery of the $1.67M churn problem**, achieved with focused intervention on roughly 30% of the customer base. Aggressive implementation, higher retention success rates, or compounding effects from multiple programs working in concert would push this number significantly higher.

The targeting precision matters: a broad retention spray-and-pray approach would burn most of its budget on customers who weren't going to leave anyway. The surgical approach concentrates spend on the segments where impact is highest.

---

## Methodology Notes & Limitations

- **Data source:** IBM Telco Customer Churn dataset (7,043 customers, anonymized). Findings should be re-validated against the actual telecom's data before operational rollout.
- **Model performance:** ROC-AUC of 0.839 is strong for tabular data, but real-world performance depends on data drift, which should be monitored over time.
- **Cost assumptions:** Retention offer cost ($50/customer) and retention success rate (30%) are industry-typical but should be calibrated against the actual telecom's historical campaign data.
- **External factors:** This analysis does not incorporate competitive dynamics (e.g., fiber pricing from competitors), service quality data (e.g., outage history), or macroeconomic factors. A production model would integrate these signals.
- **Causation vs correlation:** Service add-ons correlate strongly with retention but causation cannot be confirmed from this dataset alone. A randomized rollout test is recommended before scaling the add-on attachment recommendation.

---

## Supporting Materials

- **Interactive dashboard:** [Power BI live link in README]
- **GitHub repository:** [github.com/Jaswanthi-A/churn-analysis](https://github.com/Jaswanthi-A/churn-analysis)
- **Notebooks:** `notebooks/01_eda.ipynb` (exploratory analysis), `notebooks/02_modeling.ipynb` (predictive modeling)