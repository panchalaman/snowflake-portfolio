/* 
=============================================================================
Module: 03 - Security & Data Governance
Scenario: Applying PII protection across the data warehouse seamlessly.
=============================================================================
*/

USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS PORTFOLIO_CORP_DB;
CREATE SCHEMA IF NOT EXISTS GOVERNANCE;
USE SCHEMA PORTFOLIO_CORP_DB.GOVERNANCE;

-----------------------------------------------------------------------------
-- 1. CREATE ROLES 
-----------------------------------------------------------------------------
CREATE ROLE IF NOT EXISTS DATA_ENGINEER;
CREATE ROLE IF NOT EXISTS HR_PAYROLL;
CREATE ROLE IF NOT EXISTS GENERAL_ANALYST;

-----------------------------------------------------------------------------
-- 2. TAG-BASED DATA MASKING (Column Level Security)
-----------------------------------------------------------------------------
-- A) Define a generic classification tag.
CREATE OR REPLACE TAG SENSITIVE_DATA_CLASSIFICATION
  COMMENT = 'Tag used to classify columns containing PII or financial data.';

-- B) Create the masking policy. Note how it evaluates the executing user's role.
CREATE OR REPLACE MASKING POLICY tag_based_mask 
  AS (val string) RETURNS string ->
  CASE
    WHEN CURRENT_ROLE() IN ('HR_PAYROLL', 'ACCOUNTADMIN') THEN val
    ELSE '*** CONFIDENTIAL ***'
  END;

-- C) Attach the masking policy TO THE TAG (Not the table directly)
ALTER TAG SENSITIVE_DATA_CLASSIFICATION 
  SET MASKING POLICY tag_based_mask;

-----------------------------------------------------------------------------
-- 3. APPLY GOVERNANCE TO TABLES
-----------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS PORTFOLIO_CORP_DB.EMPLOYEES;

-- Create an employee table. We assign the tag specifically to the sensitive columns.
CREATE OR REPLACE TABLE PORTFOLIO_CORP_DB.EMPLOYEES.DIRECTORY (
  EMP_ID NUMBER,
  NAME VARCHAR,
  TITLE VARCHAR,
  SALARY VARCHAR WITH TAG (GOVERNANCE.SENSITIVE_DATA_CLASSIFICATION = 'FINANCIAL'),
  SSN VARCHAR WITH TAG (GOVERNANCE.SENSITIVE_DATA_CLASSIFICATION = 'PII_HIGH')
);

INSERT INTO PORTFOLIO_CORP_DB.EMPLOYEES.DIRECTORY VALUES 
  (101, 'Jane Doe', 'Software Engineer', '$150000', '123-45-678'),
  (102, 'John Smith', 'Marketing Coord', '$85000',  '987-65-432');

-- Now, if a DATA_ENGINEER runs:
-- SELECT * FROM PORTFOLIO_CORP_DB.EMPLOYEES.DIRECTORY;
-- They will see the IDs, Names, and Titles, but SALARY and SSN will be "*** CONFIDENTIAL ***"

-----------------------------------------------------------------------------
-- 4. ROW ACCESS POLICIES (Row Level Security)
-----------------------------------------------------------------------------
CREATE OR REPLACE TABLE PORTFOLIO_CORP_DB.EMPLOYEES.ROLE_MAPPING (
    ROLE_NAME VARCHAR,
    DEPARTMENT_ACCESS VARCHAR
);

CREATE OR REPLACE ROW ACCESS POLICY department_filter 
  AS (department_param VARCHAR) RETURNS BOOLEAN ->
  CURRENT_ROLE() IN ('ACCOUNTADMIN', 'HR_PAYROLL') 
  OR 
  EXISTS (
    SELECT 1 FROM PORTFOLIO_CORP_DB.EMPLOYEES.ROLE_MAPPING 
    WHERE ROLE_NAME = CURRENT_ROLE() AND DEPARTMENT_ACCESS = department_param
  );

-- Assuming we had a DEPT column on DIRECTORY, we would execute:
-- ALTER TABLE PORTFOLIO_CORP_DB.EMPLOYEES.DIRECTORY ADD ROW ACCESS POLICY department_filter ON (DEPARTMENT);
