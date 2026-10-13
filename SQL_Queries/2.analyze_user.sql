/*
Block 6: user behaviour (registrations, MAU, growth and retention).
A user's registration date = the date of their first order.
*/

-- 6.1 Registrations and active users --------------------------------------------

-- 1. Registration date per user (MIN(order_date))

-- 2. Registrations per month (CTE reg_dates)

-- 3. Monthly active users (MAU)


-- 6.2 Window functions -----------------------------------------------------------

-- 4. Registrations running total (SUM() OVER)

-- 5. MAU this month vs last month (LAG)

-- 6. MAU growth % (NULLIF, cast to numeric)

-- 7. Order growth %


-- 6.3 Retention ------------------------------------------------------------------

-- 8. Monthly retention rate (self-join on user_id and next month)
