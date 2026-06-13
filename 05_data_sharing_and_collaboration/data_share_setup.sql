/* 
=============================================================================
Module: 05 - Data Sharing
Scenario: Providing a partner live access to our Fleet Maintenance Analytics.
=============================================================================
*/

USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS PORTFOLIO_SHARES_DB;
CREATE SCHEMA IF NOT EXISTS OUTBOUND;
USE SCHEMA PORTFOLIO_SHARES_DB.OUTBOUND;

-----------------------------------------------------------------------------
-- 1. WRAP DATA IN SECURE VIEWS
-----------------------------------------------------------------------------
-- Never share base tables directly. Secure Views prevent external users 
-- from seeing the DDL and bypass any internal governance we have attached.
CREATE OR REPLACE SECURE VIEW OUTBOUND.PARTNER_FLEET_MAINTENANCE_V
  COMMENT = 'Secure view exposing only highly aggregated anomalous truck data for partners.'
AS
  SELECT 
    TRUCK_ID,
    REPORT_WEEK,
    DAYS_OVER_SPEED_LIMIT,
    DAYS_OVERHEATING
  FROM PORTFOLIO_IOT_DB.ANALYTICS.DT_FLEET_WEEKLY_ALERTS
  WHERE DAYS_OVERHEATING > 0; -- Only expose trucks that actually need maintenance

-----------------------------------------------------------------------------
-- 2. CREATE THE SHARE OBJECT
-----------------------------------------------------------------------------
CREATE SHARE IF NOT EXISTS MAINTENANCE_PARTNER_SHARE
  COMMENT = 'Live data share for AutoFix Inc.';

-----------------------------------------------------------------------------
-- 3. GRANT PERMISSIONS TO THE SHARE
-----------------------------------------------------------------------------
-- Shares act similarly to roles. We grant usage on the DB, Schema, and View.
GRANT USAGE ON DATABASE PORTFOLIO_SHARES_DB TO SHARE MAINTENANCE_PARTNER_SHARE;
GRANT USAGE ON SCHEMA PORTFOLIO_SHARES_DB.OUTBOUND TO SHARE MAINTENANCE_PARTNER_SHARE;
GRANT SELECT ON VIEW PORTFOLIO_SHARES_DB.OUTBOUND.PARTNER_FLEET_MAINTENANCE_V TO SHARE MAINTENANCE_PARTNER_SHARE;

-----------------------------------------------------------------------------
-- 4. ADD CONSUMER ACCOUNTS
-----------------------------------------------------------------------------
-- We specify the target Snowflake account locator (e.g., xy12345.us-east-1)
-- Once executed, the partner instantly sees this share in their inbound list.

-- ALTER SHARE MAINTENANCE_PARTNER_SHARE ADD ACCOUNTS = xy12345;

/* 
Note on Reader Accounts:
If the 3rd party *did not* have a Snowflake account, we could spin up a 
"Reader Account" for them. They log into an environment we pay for to consume 
this specific share. 

Example:
CREATE MANAGED ACCOUNT AUTOFIX_READER_ACCT
  ADMIN_NAME = 'autofix_admin', ADMIN_PASSWORD = 'TemporaryPassword123'
  TYPE = READER, COMMENT = 'Reader account for AutoFix Inc';
*/
