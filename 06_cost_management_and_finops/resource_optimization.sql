/* 
=============================================================================
Module: 06 - FinOps and Cost Optimization
Scenario: Hardening compute elasticity against budget overruns.
=============================================================================
*/

USE ROLE ACCOUNTADMIN;

-----------------------------------------------------------------------------
-- 1. OPTIMIZED VIRTUAL WAREHOUSE CREATION
-----------------------------------------------------------------------------
-- Rather than creating a generic data warehouse, they are configured for specific 
-- workloads to ensure money isn't wasted idling.

CREATE OR REPLACE WAREHOUSE BI_REPORTING_WH
  WAREHOUSE_SIZE = 'SMALL'
  -- Automatically spins down after 60 seconds of inactivity to save credits.
  AUTO_SUSPEND = 60 
  AUTO_RESUME = TRUE
  -- Multi-cluster routing. Starts with 1 cluster, spins up to 3 during traffic spikes (like Monday morning reports)
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 3
  -- Waits slightly for a cluster to become available before spinning up a new one (Cost saving)
  SCALING_POLICY = 'ECONOMY' 
  COMMENT = 'Dedicated compute for BI Dashboard consumers.';

-----------------------------------------------------------------------------
-- 2. RESOURCE MONITORS (The Financial Kill Switch)
-----------------------------------------------------------------------------
-- We assign a monitor with a strict monthly credit limit to the warehouse.
-- 1 Credit ~= $2.00 - $4.00 depending on the edition.

CREATE OR REPLACE RESOURCE MONITOR strict_reporting_budget
  CREDIT_QUOTA = 150
  FREQUENCY = MONTHLY
  START_TIMESTAMP = IMMEDIATELY
  TRIGGERS 
    ON 75 PERCENT DO NOTIFY -- Send alert to admins at 75%
    ON 90 PERCENT DO NOTIFY -- Send alert at 90%
    ON 100 PERCENT DO SUSPEND -- Soft kill: Suspend after current queries finish
    ON 110 PERCENT DO SUSPEND_IMMEDIATE; -- Hard kill: Kill active queries immediately if budget severely breached

-- Assign the monitor to the previously created warehouse
ALTER WAREHOUSE BI_REPORTING_WH SET RESOURCE_MONITOR = strict_reporting_budget;

-- (Optional) Account Level monitor to prevent the overall account from breaching budget
-- CREATE RESOURCE MONITOR account_budget CREDIT_QUOTA = 2000 ...
-- ALTER ACCOUNT SET RESOURCE_MONITOR = account_budget;

-----------------------------------------------------------------------------
-- 3. STATEMENT TIMEOUTS
-----------------------------------------------------------------------------
-- Prevents a bad Cartesian JOIN (cross join) from spinning wheels for hours.
-- If a query on this warehouse runs longer than 1 hour (3600 seconds), kill it.

ALTER WAREHOUSE BI_REPORTING_WH SET STATEMENT_TIMEOUT_IN_SECONDS = 3600;
