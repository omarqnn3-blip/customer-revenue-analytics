/* =============================================================================
   Customer & Revenue Analytics  —  Business Query Set
   Project : Customer & Revenue Analytics Dashboard
   Author  : Omar Quinn
   Source  : telco_churn_cleaned.csv  (output of notebooks/churn_analysis.ipynb)

   Assumes the cleaned dataset is loaded into a table named `telco_churn`.
   Derived columns available from the cleaning notebook:
       Churn_Flag (1/0), Revenue_At_Risk, Tenure_Group, Customer_Value_Segment

   Written in standard SQL (PostgreSQL-compatible; also runs in SQLite/MySQL).
   Identifiers are left unquoted, so case folds consistently across engines.
   ============================================================================= */


/* -----------------------------------------------------------------------------
   1. OVERALL CHURN RATE
   Business question: What share of our customer base have we lost?
   --------------------------------------------------------------------------- */
SELECT
    COUNT(*)                                  AS total_customers,
    SUM(Churn_Flag)                           AS churned_customers,
    ROUND(100.0 * AVG(Churn_Flag), 1)         AS churn_rate_pct
FROM telco_churn;
-- How it helps: the single headline number leadership tracks each period and
-- the baseline every other cut in this file is compared against.


/* -----------------------------------------------------------------------------
   2. MONTHLY RECURRING REVENUE (MRR) & ARPU
   Business question: How much recurring revenue does the base generate, and
   how much does an average customer contribute?
   --------------------------------------------------------------------------- */
SELECT
    COUNT(*)                                  AS total_customers,
    ROUND(SUM(MonthlyCharges), 0)             AS monthly_revenue,
    ROUND(AVG(MonthlyCharges), 2)             AS arpu          -- avg revenue per user
FROM telco_churn;
-- How it helps: sizes the business in dollars and gives the ARPU benchmark used
-- to judge whether a segment is worth more or less than the average customer.


/* -----------------------------------------------------------------------------
   3. REVENUE AT RISK
   Business question: How much monthly revenue walks out with churned customers,
   and what share of MRR is that?
   --------------------------------------------------------------------------- */
SELECT
    ROUND(SUM(MonthlyCharges), 0)                                   AS monthly_revenue,
    ROUND(SUM(Revenue_At_Risk), 0)                                  AS revenue_at_risk,
    ROUND(100.0 * SUM(Revenue_At_Risk) / SUM(MonthlyCharges), 1)    AS revenue_at_risk_pct
FROM telco_churn;
-- How it helps: reframes churn from a count into a dollar figure. Because the
-- revenue-at-risk % runs higher than the customer churn %, it proves churners
-- are above-average value — the core argument for funding retention.


/* -----------------------------------------------------------------------------
   4. CHURN BY CONTRACT TYPE
   Business question: Which contract types keep customers, and which leak them?
   --------------------------------------------------------------------------- */
SELECT
    Contract,
    COUNT(*)                                  AS customers,
    ROUND(100.0 * AVG(Churn_Flag), 1)         AS churn_rate_pct,
    ROUND(SUM(Revenue_At_Risk), 0)            AS revenue_at_risk
FROM telco_churn
GROUP BY Contract
ORDER BY churn_rate_pct DESC;
-- How it helps: contract length is the strongest, most actionable churn lever.
-- A large gap between month-to-month and longer terms is a direct case for
-- incentivising annual contracts.


/* -----------------------------------------------------------------------------
   5. CHURN BY TENURE GROUP
   Business question: At what stage of the customer lifecycle do we lose people?
   --------------------------------------------------------------------------- */
SELECT
    Tenure_Group,
    COUNT(*)                                  AS customers,
    ROUND(100.0 * AVG(Churn_Flag), 1)         AS churn_rate_pct
FROM telco_churn
GROUP BY Tenure_Group
ORDER BY MIN(tenure);                          -- keep lifecycle order, not rate order
-- How it helps: shows whether churn is an early-life (onboarding) problem or a
-- late-life (loyalty) problem, which decides where retention spend should go.


/* -----------------------------------------------------------------------------
   6. CHURN BY PAYMENT METHOD
   Business question: Does how a customer pays relate to whether they leave?
   --------------------------------------------------------------------------- */
SELECT
    PaymentMethod,
    COUNT(*)                                  AS customers,
    ROUND(100.0 * AVG(Churn_Flag), 1)         AS churn_rate_pct
FROM telco_churn
GROUP BY PaymentMethod
ORDER BY churn_rate_pct DESC;
-- How it helps: manual payment methods often signal lower commitment. If one
-- method churns far more, nudging those customers to auto-pay is a cheap fix.


/* -----------------------------------------------------------------------------
   7. CHURN BY INTERNET SERVICE
   Business question: Is churn concentrated in a particular internet product?
   --------------------------------------------------------------------------- */
SELECT
    InternetService,
    COUNT(*)                                  AS customers,
    ROUND(100.0 * AVG(Churn_Flag), 1)         AS churn_rate_pct,
    ROUND(AVG(MonthlyCharges), 2)             AS avg_monthly_charge
FROM telco_churn
GROUP BY InternetService
ORDER BY churn_rate_pct DESC;
-- How it helps: pairs churn with price per product. A high-churn, high-price
-- product points to a value-for-money problem the product team can own.


/* -----------------------------------------------------------------------------
   8. CHURN BY CUSTOMER VALUE SEGMENT
   Business question: Do our higher-spending customers stay or leave?
   --------------------------------------------------------------------------- */
SELECT
    Customer_Value_Segment,
    COUNT(*)                                  AS customers,
    ROUND(100.0 * AVG(Churn_Flag), 1)         AS churn_rate_pct
FROM telco_churn
GROUP BY Customer_Value_Segment
ORDER BY churn_rate_pct DESC;
-- How it helps: if churn rises with spend, the business is losing exactly the
-- customers it can least afford to lose — a red flag worth acting on.


/* -----------------------------------------------------------------------------
   9. AVERAGE MONTHLY CHARGES BY CHURN STATUS
   Business question: Do customers who leave pay more or less than those who stay?
   --------------------------------------------------------------------------- */
SELECT
    Churn,
    COUNT(*)                                  AS customers,
    ROUND(AVG(MonthlyCharges), 2)             AS avg_monthly_charge,
    ROUND(AVG(tenure), 1)                     AS avg_tenure_months
FROM telco_churn
GROUP BY Churn
ORDER BY Churn;
-- How it helps: a higher average bill among churners confirms the revenue-vs-
-- customer churn gap at the individual level and supports targeting high-bill
-- accounts for retention outreach.


/* -----------------------------------------------------------------------------
   10. HIGH-VALUE CUSTOMERS AT RISK
   Business question: How many of our still-active, high-value customers sit on
   the contract type that churns most — and how much revenue do they represent?
   --------------------------------------------------------------------------- */
SELECT
    COUNT(*)                                  AS at_risk_customers,
    ROUND(SUM(MonthlyCharges), 0)             AS monthly_revenue_exposed,
    ROUND(AVG(MonthlyCharges), 2)             AS avg_monthly_charge
FROM telco_churn
WHERE Customer_Value_Segment = 'High Value'
  AND Contract              = 'Month-to-month'
  AND Churn_Flag            = 0;               -- still active = still saveable
-- How it helps: turns analysis into a target list. These are the accounts a
-- retention team should call first; swap COUNT(*) for SELECT customerID to
-- export the actual outreach list.


/* -----------------------------------------------------------------------------
   11. BEST AND WORST CUSTOMER SEGMENTS
   Business question: Across contract x value combinations, which segments are
   the most loyal and which are the most at-risk?
   --------------------------------------------------------------------------- */
WITH segment_perf AS (
    SELECT
        Contract,
        Customer_Value_Segment,
        COUNT(*)                              AS customers,
        ROUND(100.0 * AVG(Churn_Flag), 1)     AS churn_rate_pct,
        ROUND(SUM(Revenue_At_Risk), 0)        AS revenue_at_risk
    FROM telco_churn
    GROUP BY Contract, Customer_Value_Segment
)
SELECT *
FROM segment_perf
ORDER BY churn_rate_pct DESC;
-- How it helps: the top rows are the worst-performing segments (highest churn)
-- and the bottom rows the most loyal. Reading both ends shows what a healthy
-- segment looks like and which to fix first.


/* -----------------------------------------------------------------------------
   12. CUSTOMER SEGMENTS FOR RETENTION PRIORITIZATION
   Business question: Where should limited retention budget go first, balancing
   how much revenue is exposed against how fast that segment is churning?
   --------------------------------------------------------------------------- */
WITH segment_perf AS (
    SELECT
        Customer_Value_Segment,
        Contract,
        COUNT(*)                              AS customers,
        ROUND(100.0 * AVG(Churn_Flag), 1)     AS churn_rate_pct,
        ROUND(SUM(Revenue_At_Risk), 0)        AS revenue_at_risk
    FROM telco_churn
    GROUP BY Customer_Value_Segment, Contract
)
SELECT
    Customer_Value_Segment,
    Contract,
    customers,
    churn_rate_pct,
    revenue_at_risk,
    CASE
        WHEN revenue_at_risk >= 15000 AND churn_rate_pct >= 30 THEN 'Priority 1 - Urgent'
        WHEN revenue_at_risk >= 15000 OR  churn_rate_pct >= 30 THEN 'Priority 2 - Monitor'
        ELSE                                                       'Priority 3 - Stable'
    END                                       AS retention_priority
FROM segment_perf
ORDER BY revenue_at_risk DESC;
-- How it helps: combines value and risk into a single ranked action list, so
-- the business spends retention effort where the dollar payoff is largest
-- rather than where the churn percentage merely looks alarming.
