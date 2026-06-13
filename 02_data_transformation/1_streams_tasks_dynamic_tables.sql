/* 
=============================================================================
Project: Advanced Data Engineering Portfolio
Module: 02_Data_Transformation
Contents: 
  A) Streams and Tasks (Orchestrated Change Data Capture)
  B) Dynamic Tables (Declarative Transformation)
=============================================================================
Purpose:
Demonstrates moving data from raw staging structures into a modeled presentation 
layer using modern Snowflake features.
*/

USE ROLE SYSADMIN;
USE DATABASE PORTFOLIO_DB;
CREATE OR REPLACE SCHEMA PROCESSED_DATA;

-----------------------------------------------------------------------------
-- APPROACH A: STREAMS AND TASKS (Imperative CDC approach)
-----------------------------------------------------------------------------

-- 1. Create a Stream on the raw data table to capture inserts, updates, and deletes
CREATE OR REPLACE STREAM sales_raw_stream 
ON TABLE PORTFOLIO_DB.RAW_DATA.RAW_SALES
APPEND_ONLY = TRUE; -- Assuming source only gets inserts

-- 2. Create the target merged table
CREATE OR REPLACE TABLE PROCESSED_DATA.ENRICHED_SALES_HISTORY (
    TRANSACTION_ID VARCHAR(50) PRIMARY KEY,
    STORE_ID NUMBER,
    PRODUCT_ID NUMBER,
    TOTAL_AMOUNT NUMBER(12, 2),
    PROCESSED_TIMESTAMP TIMESTAMP_NTZ
);

-- 3. Create a Task that processes the stream
-- It runs every 10 minutes and uses a MERGE statement to avoid duplicates.
CREATE OR REPLACE TASK merge_sales_data_task
    WAREHOUSE = compute_wh
    SCHEDULE = '10 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('sales_raw_stream')
AS 
    MERGE INTO PROCESSED_DATA.ENRICHED_SALES_HISTORY tgt
    USING (
        SELECT 
            TRANSACTION_ID, 
            STORE_ID, 
            PRODUCT_ID, 
            QUANTITY * PRICE AS TOTAL_AMOUNT
        FROM sales_raw_stream
    ) src
    ON tgt.TRANSACTION_ID = src.TRANSACTION_ID
    WHEN NOT MATCHED THEN 
        INSERT (TRANSACTION_ID, STORE_ID, PRODUCT_ID, TOTAL_AMOUNT, PROCESSED_TIMESTAMP) 
        VALUES (src.TRANSACTION_ID, src.STORE_ID, src.PRODUCT_ID, src.TOTAL_AMOUNT, CURRENT_TIMESTAMP());

-- Resume the task (Tasks are suspended by default upon creation)
ALTER TASK merge_sales_data_task RESUME;


-----------------------------------------------------------------------------
-- APPROACH B: DYNAMIC TABLES (Declarative automated transformation)
-----------------------------------------------------------------------------

-- Modern approaches in Snowflake favor Dynamic Tables over Streams+Tasks 
-- when the required transformation can be expressed declaratively.

-- 1. Create a Dynamic Table representing an aggregation
-- Snowflake will automatically refresh this table continuously trying to meet the lag target.

CREATE OR REPLACE DYNAMIC TABLE PROCESSED_DATA.STORE_DAILY_AGGREGATES
    TARGET_LAG = '1 hour'
    WAREHOUSE = compute_wh
AS
SELECT 
    STORE_ID,
    DATE(TRANSACTION_DATE) AS SALES_DATE,
    COUNT(TRANSACTION_ID) AS DAILY_TXN_COUNT,
    SUM(QUANTITY) AS DAILY_UNITS_SOLD,
    SUM(QUANTITY * PRICE) AS DAILY_REVENUE
FROM PORTFOLIO_DB.RAW_DATA.RAW_SALES
GROUP BY STORE_ID, DATE(TRANSACTION_DATE);

-- Dynamic tables simplify pipeline architectures by delegating dependency tracking and 
-- incremental refreshing internally to Snowflake's compute engine.
