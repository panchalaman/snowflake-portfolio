/* 
=============================================================================
Module: 02 - Declarative Transformations
Scenario: Building the Analytics (Gold) layer using Dynamic Tables
=============================================================================
*/

USE ROLE SYSADMIN;
CREATE DATABASE IF NOT EXISTS PORTFOLIO_IOT_DB;
CREATE SCHEMA IF NOT EXISTS ANALYTICS;
USE SCHEMA PORTFOLIO_IOT_DB.ANALYTICS;

-----------------------------------------------------------------------------
-- 1. DAILY AGGREGATIONS (Level 1 Dynamic Table)
-----------------------------------------------------------------------------
-- Rather than writing a scheduled task to roll up data, we define the end state.
-- Snowflake continuously aims to keep this table within 1 hour of the base table.

CREATE OR REPLACE DYNAMIC TABLE DT_TRUCK_DAILY_STATS
  TARGET_LAG = '1 hour'
  WAREHOUSE = 'COMPUTE_WH'
  COMMENT = 'Daily rollup of truck telematics. Incrementally refreshed.'
AS
  SELECT 
    TRUCK_ID,
    DATE(EVENT_TIMESTAMP) AS REPORT_DATE,
    COUNT(*) AS TOTAL_EVENTS_LOGGED,
    MAX(SPEED_MPH) AS MAX_SPEED_RECORDED,
    AVG(SPEED_MPH) AS AVG_SPEED,
    MAX(ENGINE_TEMP) AS MAX_TEMP_RECORDED,
    AVG(ENGINE_TEMP) AS AVG_TEMP
  FROM PORTFOLIO_IOT_DB.HARMONIZED.TRUCK_TELEMETRY_FLAT
  GROUP BY TRUCK_ID, DATE(EVENT_TIMESTAMP);


-----------------------------------------------------------------------------
-- 2. CHAINED DEPENDENCIES (Level 2 Dynamic Table)
-----------------------------------------------------------------------------
-- Dynamic tables natively understand their dependencies. 
-- By referencing DT_TRUCK_DAILY_STATS, Snowflake knows it must refresh the base DT 
-- before refreshing this subordinate DT. No Airflow DAG needed.

CREATE OR REPLACE DYNAMIC TABLE DT_FLEET_WEEKLY_ALERTS
  TARGET_LAG = 'DOWNSTREAM' -- Automatically refreshes based on downstream consumers/needs.
  WAREHOUSE = 'COMPUTE_WH'
  COMMENT = 'Flags highly anomalous trucks for maintenance.'
AS
  SELECT 
    TRUCK_ID,
    DATE_TRUNC('WEEK', REPORT_DATE) AS REPORT_WEEK,
    COUNT(IFF(MAX_SPEED_RECORDED > 80, 1, NULL)) AS DAYS_OVER_SPEED_LIMIT,
    COUNT(IFF(MAX_TEMP_RECORDED > 220, 1, NULL)) AS DAYS_OVERHEATING
  FROM DT_TRUCK_DAILY_STATS
  GROUP BY TRUCK_ID, DATE_TRUNC('WEEK', REPORT_DATE)
  HAVING DAYS_OVER_SPEED_LIMIT > 0 OR DAYS_OVERHEATING > 0;

-- Verification commands (Optional)
-- SHOW DYNAMIC TABLES;
-- SELECT * FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY(NAME_PREFIX => 'DT_'));
