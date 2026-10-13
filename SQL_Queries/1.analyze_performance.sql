/*
Blocks 4 and 5: data exploration and business performance (revenue, cost, profit).
For each query, add one comment line saying which business question it answers.
*/

-- 0. Data exploration (Block 4) -----------------------------------------------

-- 0.1 Preview each table (LIMIT 5)

-- 0.2 Date coverage: MIN / MAX of order_date and stocking_date

-- 0.3 Distinct users, distinct orders, distinct meals ordered

-- 0.4 Rows with NULL key columns

-- 0.5 meal_ids in orders / stock that don't exist in meals (LEFT JOIN ... IS NULL)


-- 5.1 Revenue -------------------------------------------------------------------

-- 1. Revenue per order_id

-- 2. Total revenue for user_id 15

-- 3. Top 10 customers by revenue

-- 4. Weekly revenue in June 2018 (DATE_TRUNC('week', ...))

-- 5. Monthly revenue


-- 5.2 Cost ----------------------------------------------------------------------

-- 6. Total cost of all stocked meals

-- 7. Top 5 meal_ids by stocking cost

-- 8. Average monthly cost before September 2018 (CTE)


-- 5.3 Profit --------------------------------------------------------------------

-- 9. Revenue, cost and profit per eatery (two CTEs joined on eatery)

-- 10. Monthly revenue, cost, profit and margin_pct (two CTEs joined on delivr_month)
