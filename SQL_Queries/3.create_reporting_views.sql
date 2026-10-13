/*
Block 7: reporting views for Power BI.
Rule: no ORDER BY and no LIMIT inside views.
*/

CREATE SCHEMA IF NOT EXISTS reporting;

-- reporting.v_monthly_pnl       (delivr_month, revenue, cost, profit, margin_pct)

-- reporting.v_eatery_pnl        (eatery, revenue, cost, profit)

-- reporting.v_customer_revenue  (user_id, revenue, orders)

-- reporting.v_monthly_users     (delivr_month, regs, regs_rt, mau, last_mau, mau_growth_pct, orders, order_growth_pct, retention_pct)

-- reporting.v_order_lines       (order_date, user_id, order_id, meal_id, eatery, order_quantity, revenue)
