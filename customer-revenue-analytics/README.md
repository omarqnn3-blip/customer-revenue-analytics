# Customer & Revenue Analytics Dashboard

End-to-end churn and revenue analysis for a telecom customer base of **7,043 customers**, built to answer a single business question: *who is leaving, why, and how much recurring revenue is at stake?*

**Author:** Omar Quinn, Data & BI Analyst
**Tools:** SQL · Python (pandas) · Power BI

---

## The business problem

The provider was losing about a quarter of its customers each year with no clear view of which accounts were leaving or how much revenue was exposed. Retention effort was spread evenly instead of aimed at the customers that mattered most.

## What I did

1. **Cleaned the raw data** in Python (`notebooks/churn_analysis.ipynb`), handled the blank `TotalCharges` values, cast types, and engineered the fields the rest of the analysis relies on: `Churn_Flag`, `Revenue_At_Risk`, `Tenure_Group`, and `Customer_Value_Segment`.
2. **Built a business query set** in SQL (`sql/customer_revenue_analytics_queries.sql`), 12 documented queries covering churn rate, MRR/ARPU, revenue at risk, and churn cut by contract, tenure, payment method, internet service, and value segment.
3. **Designed a 4-page Power BI dashboard** (`dashboard/`), an executive overview, a customer-base view, a revenue view, and a retention-priority view.

## Key findings

- **Revenue churn (30.5%) runs ~4 points hotter than customer churn (26.5%).** The customers leaving are billed above average, so churn costs more in dollars than in headcount.
- **Contract length is the strongest lever.** Month-to-month customers churn at **42.7%**, versus 11.3% (one year) and 2.8% (two year).
- **Payment method matters.** Electronic-check payers churn at **45.3%**: roughly triple the automatic methods (~15–17%).
- **Churn concentrates early.** The 0–12 month tenure group churns most and tapers with loyalty.
- **The segment to defend first:** High-Value, month-to-month customers, **52.6% churn** and the largest revenue-at-risk pool. That's **599 still-active accounts** carrying about **$56.9K in monthly revenue**.

## Recommendations

1. Prioritize retention on High-Value month-to-month accounts, highest churn, largest dollar exposure.
2. Move customers onto annual / two-year contracts.
3. Nudge electronic-check payers toward automatic payment.
4. Strengthen onboarding in the first 12 months.

## Repo structure

```
customer-revenue-analytics/
├── notebooks/    churn_analysis.ipynb           # data cleaning + feature engineering
├── sql/          customer_revenue_analytics_queries.sql   # 12 business queries
├── dashboard/    Customer___Revenue_Analytics.pbix         # Power BI file
│                 Customer___Revenue_Analytics.pdf          # exported dashboard
└── screenshots/  01–04 .png                      # dashboard pages
```

## Data

Based on the public Telco Customer Churn dataset (7,043 rows). The cleaning notebook outputs `telco_churn_cleaned.csv`, which the SQL query set assumes is loaded into a table named `telco_churn`.

---

*Part of my analytics portfolio. See the full case study on my portfolio site.*
