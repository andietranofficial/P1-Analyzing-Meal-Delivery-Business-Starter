/* ---------------------------------------------------------------------
   PART A: Access to Blob Storage (run once per database)
   --------------------------------------------------------------------- */
SELECT DB_NAME() AS CurrentDatabase;   -- make sure you are at the right database

-- create master key once
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'your-strong-password'; -- change this to a strong password and keep it secure
GO

-- create credential for Azure Blob Storage access
CREATE DATABASE SCOPED CREDENTIAL MyCred
WITH IDENTITY = 'SHARED ACCESS SIGNATURE',
--generate SAS token in a short period of time for security reasons: 14/10-14/12-2026
SECRET = 'your-sas-token'; 

-- verify it exists
SELECT name, credential_identity
FROM sys.database_scoped_credentials;

-- create external data source for Azure Blob Storage
CREATE EXTERNAL DATA SOURCE MyBlobStorage
WITH (
    TYPE = BLOB_STORAGE,
    LOCATION = 'https://<storage-account>.blob.core.windows.net/<container>',
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

DROP TABLE IF EXISTS delivery.meals;
CREATE TABLE delivery.meals (
  meal_id INT,
  eatery NVARCHAR(255),  -- Changed TEXT to NVARCHAR for SQL Server
  meal_price FLOAT,
  meal_cost FLOAT
);

DROP TABLE IF EXISTS delivery.orders;
CREATE TABLE delivery.orders (
  order_date DATE,
  user_id INT,
  order_id INT,
  meal_id INT,
  order_quantity INT
);

DROP TABLE IF EXISTS delivery.stock_stage;
CREATE TABLE delivery.stock_stage (
  stocking_date NVARCHAR(255), -- convert column type later to DATE after loading data
  meal_id INT,
  stocked_quantity INT
);

DROP TABLE IF EXISTS delivery.stock;
CREATE TABLE delivery.stock (
  stocking_date DATE, 
  meal_id INT,
  stocked_quantity INT
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
    FIRSTROW = 1, -- Skip header row
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a'
);

BULK INSERT delivery.stock_stage
FROM 'stock.csv'  
WITH (
    DATA_SOURCE = 'MyBlobStorage',
    FORMAT = 'CSV',
    FIRSTROW = 1, -- Skip header row
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a'
);

-- Convert stocking_date to DATE format and insert into final stock table
INSERT INTO delivery.stock (stocking_date, meal_id, stocked_quantity)

SELECT 
    TRY_CAST(stocking_date AS DATE) AS stocking_date, 
    meal_id, 
    stocked_quantity
FROM delivery.stock_stage;


-- Check for any rows that failed to convert to DATE format
SELECT *
FROM delivery.stock_stage
WHERE TRY_CONVERT(date, stocking_date, 103) IS NULL;
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


SELECT name, credential_identity FROM sys.database_scoped_credentials;
SELECT name, location FROM sys.external_data_sources;

DROP EXTERNAL DATA SOURCE RetailBlob;      -- uses MyCred, so it goes first
DROP DATABASE SCOPED CREDENTIAL RetailCred;
