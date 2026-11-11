/* ---------------------------------------------------------------------
   PART A: Access to Blob Storage (run once per database)
   --------------------------------------------------------------------- */
SELECT DB_NAME() AS CurrentDatabase;   -- make sure you are at the right database

-- create master key once
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'DA123456789!'; -- change this to a strong password and keep it secure
GO

-- create credential for Azure Blob Storage access
CREATE DATABASE SCOPED CREDENTIAL MyCred
WITH IDENTITY = 'SHARED ACCESS SIGNATURE',
--generate SAS token in a short period of time for security reasons: 14/10-14/12-2026
SECRET = 'sv=2026-02-06&ss=bfqt&srt=sco&sp=rwdlacupiytfx&se=2026-12-14T19:35:28Z&st=2026-10-14T10:20:28Z&spr=https&sig=Izqj1RHHu4lH3ndKNpfPiNk8jT4TEzutYksHYpooV44%3D'; 

-- verify it exists
SELECT name
FROM sys.database_scoped_credentials;

-- create external data source for Azure Blob Storage
CREATE EXTERNAL DATA SOURCE MyBlobStorage
WITH (
    TYPE = BLOB_STORAGE,
    LOCATION = 'https://stmealdelivery.blob.core.windows.net/data',
    CREDENTIAL = MyCred
);

-- verify it exists
SELECT name, location FROM sys.external_data_sources;
GO

/* ---------------------------------------------------------------------
   PART B: Creat tables and load data with BULK INSERT
   --------------------------------------------------------------------- */

-- create schemas in database
CREATE SCHEMA delivery;
GO

-- drop child tables first: orders and stock have foreign keys to meals
DROP TABLE IF EXISTS delivery.orders;
DROP TABLE IF EXISTS delivery.stock;
DROP TABLE IF EXISTS delivery.meals;

CREATE TABLE delivery.meals (
  meal_id INT NOT NULL PRIMARY KEY,
  eatery NVARCHAR(255),  -- Changed TEXT to NVARCHAR for SQL Server
  meal_price FLOAT,
  meal_cost FLOAT
);

-- one row per meal in an order, so the key is (order_id, meal_id)
CREATE TABLE delivery.orders (
  order_date DATE NOT NULL,
  user_id INT NOT NULL,
  order_id INT NOT NULL,
  meal_id INT NOT NULL REFERENCES delivery.meals (meal_id),
  order_quantity INT,
  CONSTRAINT pk_orders PRIMARY KEY (order_id, meal_id)
);

DROP TABLE IF EXISTS delivery.stock_stage;
CREATE TABLE delivery.stock_stage (
  stocking_date NVARCHAR(255), -- convert column type later to DATE after loading data
  meal_id INT,
  stocked_quantity INT
);

-- one row per meal per stocking date
CREATE TABLE delivery.stock (
  stocking_date DATE NOT NULL,
  meal_id INT NOT NULL REFERENCES delivery.meals (meal_id),
  stocked_quantity INT,
  CONSTRAINT pk_stock PRIMARY KEY (stocking_date, meal_id)
);

-- Load data using BULK INSERT 
BULK INSERT delivery.meals
FROM 'meals.csv'  
WITH (
    DATA_SOURCE = 'MyBlobStorage',
    FORMAT = 'CSV',
    FIRSTROW = 1, -- no header row, start at row
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a'
);

BULK INSERT delivery.orders
FROM 'orders.csv'  
WITH (
    DATA_SOURCE = 'MyBlobStorage',
    FORMAT = 'CSV',
    FIRSTROW = 1, -- no header row, start at row 1
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a'
);

BULK INSERT delivery.stock_stage
FROM 'stock.csv'  
WITH (
    DATA_SOURCE = 'MyBlobStorage',
    FORMAT = 'CSV',
    FIRSTROW = 1, -- no header row, start at row 1
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a'
);

-- Check for any rows that fail to convert to DATE (should return 0 rows).
-- Run this before the INSERT: stocking_date is NOT NULL, so one bad date fails the insert.
SELECT *
FROM delivery.stock_stage
WHERE TRY_CAST(stocking_date AS DATE) IS NULL;

-- Convert stocking_date to DATE format and insert into final stock table
INSERT INTO delivery.stock (stocking_date, meal_id, stocked_quantity)
SELECT
    TRY_CAST(stocking_date AS DATE) AS stocking_date,
    meal_id,
    stocked_quantity
FROM delivery.stock_stage;
GO
/* ---------------------------------------------------------------------
   PART C: Check the result and Clean up
   --------------------------------------------------------------------- */

-- Test:
SELECT COUNT(*) FROM delivery.meals;   -- 20
SELECT COUNT(*) FROM delivery.orders;  -- 28672
SELECT COUNT(*) FROM delivery.stock;   -- 133
SELECT COUNT(*) FROM delivery.stock WHERE stocking_date IS NULL;  -- 0


-- Clean up staging table
DROP TABLE delivery.stock_stage;