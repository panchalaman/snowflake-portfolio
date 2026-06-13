/* 
=============================================================================
Project: Advanced Data Engineering Portfolio
Module: 01_Data_Ingestion
Contents: Database/Schema setup, Integration, Stages, File Formats, and Snowpipe
=============================================================================
Purpose:
Demonstrates how to securely setup continuous data ingestion from AWS S3 using 
Storage Integrations and Snowpipe. This represents an enterprise standard 
configuration where credentials are NOT passed directly.
*/

USE ROLE ACCOUNTADMIN;

-- 1. Create a dedicated Database and Schema for ingestion
CREATE OR REPLACE DATABASE PORTFOLIO_DB
    COMMENT = 'Database for Snowflake Advanced Engineering Portfolio';

CREATE OR REPLACE SCHEMA PORTFOLIO_DB.RAW_DATA
    COMMENT = 'Schema defining landing zone for raw external data';

USE SCHEMA PORTFOLIO_DB.RAW_DATA;

-- 2. Create Storage Integration
-- Ensures secure access connecting Snowflake with an external S3 bucket without exposing keys.
CREATE OR REPLACE STORAGE INTEGRATION s3_portfolio_int
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'S3'
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::123456789012:role/snowflake_access_role'
    STORAGE_ALLOWED_LOCATIONS = ('s3://my-portfolio-bucket/raw/');

-- View the integration properties to configure AWS IAM trust relationship
-- DESC INTEGRATION s3_portfolio_int;

-- 3. Create a Custom File Format
-- Ideal configuration for handling large batches of comma-separated values intelligently.
CREATE OR REPLACE FILE FORMAT my_csv_format
    TYPE = 'CSV'
    COMPRESSION = 'AUTO'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '\042'
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    NULL_IF = ('NULL', 'null', '');

-- 4. Create an External Stage referencing the Integration
CREATE OR REPLACE STAGE portfolio_s3_stage
    URL = 's3://my-portfolio-bucket/raw/sales_data/'
    STORAGE_INTEGRATION = s3_portfolio_int
    FILE_FORMAT = my_csv_format
    COMMENT = 'External stage for raw sales data ingestion';

-- 5. Create Target Table for Staging
CREATE OR REPLACE TABLE RAW_SALES (
    TRANSACTION_ID VARCHAR(50),
    STORE_ID NUMBER,
    PRODUCT_ID NUMBER,
    QUANTITY NUMBER,
    PRICE NUMBER(10, 2),
    TRANSACTION_DATE TIMESTAMP_NTZ
);

-- 6. Implement Snowpipe for Auto-Ingestion
-- Creates a continuous data pipeline that automatically executes COPY INTO
-- whenever new event notifications (e.g., SQS) hit the stage.
CREATE OR REPLACE PIPE portfolio_sales_pipe 
    AUTO_INGEST = TRUE 
    COMMENT = 'Continuous ingestion pipe for raw sales.'
AS
    COPY INTO RAW_SALES (
        TRANSACTION_ID,
        STORE_ID,
        PRODUCT_ID,
        QUANTITY,
        PRICE,
        TRANSACTION_DATE
    )
    FROM @portfolio_s3_stage
    PATTERN = '.*sales_.*[.]csv'
    ON_ERROR = 'CONTINUE'; -- Ensure one bad record doesn't halt the pipeline

/* 
Note for reviewers:
In a real-world scenario, I would link the Snowflake SQS queue ARN to an S3 Event 
Notification to trigger the auto-ingestion process in real-time.
*/
