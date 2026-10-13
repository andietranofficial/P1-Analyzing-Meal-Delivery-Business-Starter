/*
Chapter 2: create the delivery schema and load the three CSVs.

Run from the repo root (PowerShell):
    $env:DATABASE_URL = ((Get-Content .env | Select-String '^DATABASE_URL=') -replace '^DATABASE_URL=', '')
    psql $env:DATABASE_URL -f SQL_Queries/0.load_mealdelivery_to_postgres.sql

Never paste your connection string into this file. Keep it in .env.
*/

\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS delivery;

-- 3.2 Create the tables ------------------------------------------------------

DROP TABLE IF EXISTS delivery.meals;
CREATE TABLE delivery.meals (
  meal_id    INT PRIMARY KEY,
  eatery     TEXT,
  meal_price ___________,
  meal_cost  ___________
);

DROP TABLE IF EXISTS delivery.orders;
CREATE TABLE delivery.orders (
  order_date     DATE,
  user_id        INT,
  order_id       INT,
  meal_id        INT,
  order_quantity INT
);

-- TODO: create delivery.stock (stocking_date, meal_id, stocked_quantity)


-- 3.3 Load meals --------------------------------------------------------------
-- each \copy must stay on ONE line

\copy delivery.meals FROM 'Datasets/meals.csv' WITH (FORMAT csv, QUOTE '''')


-- 3.4 Load orders through a staging table --------------------------------------

DROP TABLE IF EXISTS delivery.orders_stage;
CREATE TABLE delivery.orders_stage (
  order_date     TEXT,
  user_id        INT,
  order_id       INT,
  meal_id        INT,
  order_quantity INT
);

-- TODO: \copy orders.csv into delivery.orders_stage

-- Validate: should return 0 rows
SELECT * FROM delivery.orders_stage
WHERE order_date !~ '^\d{4}-\d{2}-\d{2}$';

-- TODO: INSERT INTO delivery.orders ... SELECT to_date(order_date, '__________'), ...

DROP TABLE delivery.orders_stage;


-- 3.4 Load stock through a staging table ---------------------------------------
-- Open Datasets/stock.csv first and check its date format yourself.

-- TODO: create delivery.stock_stage, \copy, validate, convert, insert, drop


COMMIT;

-- 3.5 Verify the load ----------------------------------------------------------

-- TODO: row counts for meals, orders and stock (UNION ALL)
