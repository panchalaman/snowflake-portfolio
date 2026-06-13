/* 
=============================================================================
Module: 04 - Snowpark Data Science
Scenario: Building Python embedded functions and ML processing routines.
=============================================================================
*/

USE DATABASE PORTFOLIO_IOT_DB;
CREATE SCHEMA IF NOT EXISTS DATA_SCIENCE;
USE SCHEMA PORTFOLIO_IOT_DB.DATA_SCIENCE;

-----------------------------------------------------------------------------
-- 1. SCALAR PYTHON UDF (Data Engineering Edge Cases)
-----------------------------------------------------------------------------
-- Rather than writing 50 lines of messy SQL Regex, we can securely embed Python.
-- This function can be called on millions of rows natively in the SELECT clause.

CREATE OR REPLACE FUNCTION DATA_SCIENCE.EXTRACT_ANOMALY_SIGNATURE(log_text string)
  RETURNS string
  LANGUAGE PYTHON
  RUNTIME_VERSION = '3.8'
  HANDLER = 'extract_signature'
AS
$$
import re

def extract_signature(log_text: str) -> str:
    if not log_text:
        return "UNKNOWN"
    # Example regex that might be painful in pure SQL
    match = re.search(r'ERR\-\d{3}\:(.*?)(?=\s|$)', log_text)
    if match:
        return match.group(1).strip().upper()
    return "UNKNOWN"
$$;

-- Usage mapping:
-- SELECT EXTRACT_ANOMALY_SIGNATURE('System failure ERR-404:Overheating detected in engine.') 
-- returns: 'OVERHEATING'


-----------------------------------------------------------------------------
-- 2. SNOWPARK STORED PROCEDURE (Distributed Python Logic)
-----------------------------------------------------------------------------
-- Allows running entire Python modeling scripts executing on Snowflake warehouses.

CREATE OR REPLACE PROCEDURE DATA_SCIENCE.SCORE_FLEET_TRUCKS()
  RETURNS STRING
  LANGUAGE PYTHON
  RUNTIME_VERSION = '3.8'
  -- Pull in any open source packages from the Anaconda Snowflake Channel
  PACKAGES = ('snowflake-snowpark-python', 'scikit-learn', 'pandas')
  HANDLER = 'main'
  EXECUTE AS CALLER
AS
$$
import pandas as pd
from snowflake.snowpark.functions import col

def main(session):
    # 1. Fetch data directly into a Snowpark DataFrame natively
    # This does not export data; it builds an abstact execution plan
    df = session.table("PORTFOLIO_IOT_DB.ANALYTICS.DT_FLEET_WEEKLY_ALERTS")
    
    # 2. Push down filters natively
    at_risk_df = df.filter(col("DAYS_OVERHEATING") > 5)
    
    # 3. Pull explicitly into memory only what is needed for complex processing
    pandas_df = at_risk_df.to_pandas()
    
    if len(pandas_df) == 0:
        return "SUCCESS. No trucks require critical maintenance scoring right now."
        
    """
    4. Complex Machine Learning happens here
    model = load_model()
    predictions = model.predict(pandas_df...)
    ...
    """
    
    # Return execution receipt
    target_trucks = pandas_df['TRUCK_ID'].tolist()
    return f"SCORING COMPLETE. Trucks flagged for immediate recall: {target_trucks}"
$$;

-- Invocation command (can be wrapped inside a TASK to run nightly)
-- CALL DATA_SCIENCE.SCORE_FLEET_TRUCKS();
