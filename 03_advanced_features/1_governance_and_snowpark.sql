/* 
=============================================================================
Project: Advanced Data Engineering Portfolio
Module: 03_Advanced_Features
Contents: 
  A) Row Access Policies (Data Governance)
  B) Python Snowpark Stored Procedures
=============================================================================
*/

USE ROLE SYSADMIN;
USE DATABASE PORTFOLIO_DB;
CREATE OR REPLACE SCHEMA SECURITY_AND_ML;

-----------------------------------------------------------------------------
-- APPROACH A: DATA GOVERNANCE & ROW ACCESS POLICIES
-----------------------------------------------------------------------------
-- This demonstrates enterprise-grade data security seamlessly implemented at the data level.

-- Create a lookup table identifying regional managers
CREATE OR REPLACE TABLE SECURITY_AND_ML.STORE_MANAGERS (
    STORE_ID NUMBER,
    MANAGER_ROLE_NAME VARCHAR
);

-- Note: The implementation of checking roles makes use of built-in context functions.
CREATE OR REPLACE ROW ACCESS POLICY store_manager_policy 
AS (store_id_param NUMBER) RETURNS BOOLEAN -> 
  -- Allow the super admin and data engineers full access
  CURRENT_ROLE() IN ('ACCOUNTADMIN', 'SYSADMIN', 'DATA_ENGINEER')
  OR 
  -- Otherwise, only allow if the current user's role maps to their store id
  EXISTS (
      SELECT 1 FROM SECURITY_AND_ML.STORE_MANAGERS 
      WHERE STORE_ID = store_id_param AND MANAGER_ROLE_NAME = CURRENT_ROLE()
  );

-- Apply the policy to the previously created aggregated table
ALTER TABLE PORTFOLIO_DB.PROCESSED_DATA.STORE_DAILY_AGGREGATES
  ADD ROW ACCESS POLICY store_manager_policy ON (STORE_ID);


-----------------------------------------------------------------------------
-- APPROACH B: SNOWPARK STORED PROCEDURES (Python in Snowflake)
-----------------------------------------------------------------------------
-- Rather than reading data outward to process it, we compute it tightly scaled inside it.
-- This function mimics a machine learning scoring script directly executed inside Snowflake's 
-- secure Python sandbox.

CREATE OR REPLACE PROCEDURE SECURITY_AND_ML.ANALYZE_STORE_PERFORMANCE(max_records INTEGER)
  RETURNS STRING
  LANGUAGE PYTHON
  RUNTIME_VERSION = '3.8'
  PACKAGES = ('snowflake-snowpark-python', 'pandas')
  HANDLER = 'main'
  EXECUTE AS CALLER
AS
$$
import pandas as pd
from snowflake.snowpark.functions import col

def main(session, max_records: int):
    # 1. Reference a table seamlessly through the DataFrame API
    df = session.table("PORTFOLIO_DB.PROCESSED_DATA.STORE_DAILY_AGGREGATES")
    
    # 2. Perform transformations directly pushed down into Snowflake Compute
    high_value_stores_df = df.filter(col("DAILY_REVENUE") > 10000).limit(max_records)
    
    # 3. Pull result to Pandas for quick logic if absolutely necessary
    # (Typically best done incrementally, but possible!)
    pandas_df = high_value_stores_df.to_pandas()
    
    if len(pandas_df) == 0:
        return "No highly performing stores found today."
    
    # Return a quick summary scalar
    top_store = pandas_df.loc[pandas_df['DAILY_REVENUE'].idxmax()]
    
    return f"Execution success. Top Store ID: {top_store['STORE_ID']} with Revenue: {top_store['DAILY_REVENUE']}"
$$;

-- Sample invocation
-- CALL SECURITY_AND_ML.ANALYZE_STORE_PERFORMANCE(100);
