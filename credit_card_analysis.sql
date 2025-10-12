-- Revenue Concentration Analysis
-- Top 5 revenue-generating cities and their contribution to total spends
WITH cte1 AS (
    SELECT city, SUM(amount) AS total_spend
    FROM credit_card_transcations
    GROUP BY city
),
total_spent AS (
    SELECT SUM(CAST(amount AS bigint)) AS total_amount
    FROM credit_card_transcations
)
SELECT TOP 5 
    cte1.*, 
    ROUND(total_spend * 1.0 / total_amount * 100, 2) AS percentage_contribution
FROM cte1
JOIN total_spent ON 1 = 1
ORDER BY total_spend DESC

-- Seasonal Spending Patterns
-- Highest spending month and amount for each card category

-- Highest spend month and amount for every card type

WITH cte AS (
    SELECT
        card_type,
        DATEPART(year, transaction_date) AS yt,
        DATEPART(month, transaction_date) AS mt,
        SUM(amount) AS total_spend
    FROM credit_card_transcations
    GROUP BY card_type, DATEPART(year, transaction_date), DATEPART(month, transaction_date)
)
SELECT *
FROM (
    SELECT
        *,
        RANK() OVER (PARTITION BY card_type ORDER BY total_spend DESC) AS rn
    FROM cte
) a
WHERE rn = 1

--Performance Milestone Tracking
-- Transaction snapshot when each card type hits ₹1M cumulative spending

WITH cte AS (
    SELECT *,
        SUM(amount) OVER (PARTITION BY card_type ORDER BY transaction_date, transaction_id) AS total_spend
    FROM credit_card_transcations
    --ORDER BY card_type, total_spend DESC
)
SELECT *
FROM (
    SELECT *,
        RANK() OVER (PARTITION BY card_type ORDER BY total_spend) AS rn
    FROM cte
    WHERE total_spend >= 1000000
) a
WHERE rn = 1

-- For each city, get the expense type with lowest/highest total spend

WITH cte AS (
    SELECT
        city,
        exp_type,
        SUM(amount) AS total_amount
    FROM credit_card_transcations
    GROUP BY city, exp_type
),
ranked AS (
    SELECT *,
        RANK() OVER (PARTITION BY city ORDER BY total_amount ASC) AS rn_asc,
        RANK() OVER (PARTITION BY city ORDER BY total_amount DESC) AS rn_desc
    FROM cte
)
SELECT
    city,
    MAX(CASE WHEN rn_asc = 1 THEN exp_type END) AS lowest_exp_type,
    MAX(CASE WHEN rn_desc = 1 THEN exp_type END) AS highest_exp_type
FROM ranked
GROUP BY city;

-- Female spend percentage by expense type

SELECT
    exp_type,
    SUM(CASE WHEN gender = 'F' THEN amount ELSE 0 END) * 1.0 / SUM(amount) AS percentage_female_contribution
FROM credit_card_transcations
GROUP BY exp_type
ORDER BY percentage_female_contribution DESC;


-- Card and expense type pair with highest month-over-month growth in Jan-2014

WITH cte AS (
    SELECT
        card_type,
        exp_type,
        DATEPART(year, transaction_date) AS yt,
        DATEPART(month, transaction_date) AS mt,
        SUM(amount) AS total_spend
    FROM credit_card_transcations
    GROUP BY card_type, exp_type, DATEPART(year, transaction_date), DATEPART(month, transaction_date)
)
SELECT TOP 1
    *,
    (total_spend - prev_mont_spend) AS mom_growth
FROM (
    SELECT *,
        LAG(total_spend, 1) OVER (PARTITION BY card_type, exp_type ORDER BY yt, mt) AS prev_mont_spend
    FROM cte
) A
WHERE prev_mont_spend IS NOT NULL AND yt = 2014 AND mt = 1
ORDER BY mom_growth DESC;

-- Weekend: city with highest avg transaction amount

SELECT TOP 1
    city,
    SUM(amount) * 1.0 / COUNT(1) AS ratio
FROM credit_card_transcations
WHERE DATEPART(weekday, transaction_date) IN (1, 7)
GROUP BY city
ORDER BY ratio DESC;

-- City to reach 500 transactions fastest after its first transaction

WITH cte AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY city ORDER BY transaction_date, transaction_id) AS rn
    FROM credit_card_transcations
)
SELECT TOP 1
    city,
    DATEDIFF(day, MIN(transaction_date), MAX(transaction_date)) AS datediff1
FROM cte
WHERE rn = 1 OR rn = 500
GROUP BY city
HAVING COUNT(1) = 2
ORDER BY datediff1
