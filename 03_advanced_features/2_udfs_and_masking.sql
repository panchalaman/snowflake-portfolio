/* 
=============================================================================
Project: Advanced Data Engineering Portfolio
Module: 03_Advanced_Features
Contents: 
  C) User Defined Functions (UDF)
  D) External Functions (Placeholder)
=============================================================================
*/

USE DATABASE PORTFOLIO_DB;
USE SCHEMA SECURITY_AND_ML;

-----------------------------------------------------------------------------
-- APPROACH C: PYTHON USER DEFINED FUNCTIONS
-----------------------------------------------------------------------------
-- We can register Python UDFs to perform complex text mappings or mathematical 
-- logic and use them in standard SQL queries.

CREATE OR REPLACE FUNCTION SECURITY_AND_ML.CLASSIFY_REVENUE(revenue NUMBER(12, 2))
  RETURNS VARCHAR
  LANGUAGE PYTHON
  RUNTIME_VERSION = '3.8'
  HANDLER = 'classify'
AS
$$
def classify(rev: float) -> str:
    if rev is None:
        return "UNKNOWN"
    elif rev < 1000:
        return "LOW"
    elif rev <= 5000:
        return "MEDIUM"
    else:
        return "HIGH"
$$;

-- Test the UDF natively in a query:
-- SELECT STORE_ID, DAILY_REVENUE, SECURITY_AND_ML.CLASSIFY_REVENUE(DAILY_REVENUE) AS PERF_TIER
-- FROM PORTFOLIO_DB.PROCESSED_DATA.STORE_DAILY_AGGREGATES;


-----------------------------------------------------------------------------
-- APPROACH D: SECURE UDFS (Data Masking)
-----------------------------------------------------------------------------
-- Masks sensitive PII (like email addresses or phone numbers) dynamically

CREATE OR REPLACE MASKING POLICY email_mask AS (val string) RETURNS string ->
  CASE
    WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'HR_ADMIN') THEN val
    ELSE '***MASKED***'
  END;

-- In a real scenario, applying this policy:
-- ALTER TABLE PORTFOLIO_DB.RAW_DATA.RAW_CUSTOMERS MODIFY COLUMN EMAIL SET MASKING POLICY email_mask;
