/* 
=============================================================================
Module: 01 - Streaming and CDC Pipeline
Scenario: Continuous loading and parsing of IoT truck sensors.
=============================================================================
*/

USE ROLE SYSADMIN;
CREATE DATABASE IF NOT EXISTS PORTFOLIO_IOT_DB;
USE DATABASE PORTFOLIO_IOT_DB;
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS HARMONIZED;

-----------------------------------------------------------------------------
-- 1. SETUP RAW LANDING ZONE (ELT Pattern)
-----------------------------------------------------------------------------
-- Rather than parsing the JSON on ingest, we land it natively as a VARIANT. 
-- Schema-on-read provides ultimate flexibility against upstream schema drift.
CREATE OR REPLACE TABLE RAW.TRUCK_TELEMETRY_JSON (
    SRC_FILE_NAME VARCHAR,
    LOAD_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    RAW_JSON VARIANT
);

-----------------------------------------------------------------------------
-- 2. SECURE INTEGRATION & AUTO-INGEST (SNOWPIPE)
-----------------------------------------------------------------------------
-- Assuming a mapped IAM role in AWS, this grants Snowflake secure read access.
CREATE OR REPLACE STORAGE INTEGRATION s3_iot_integration
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::123456789012:role/snowflake_role'
  STORAGE_ALLOWED_LOCATIONS = ('s3://portfolio-iot-bucket/truck_telemetry/');

-- File format customized to handle nested JSON objects efficiently.
CREATE OR REPLACE FILE FORMAT RAW.JSON_FORMAT
  TYPE = 'JSON'
  STRIP_OUTER_ARRAY = TRUE;

CREATE OR REPLACE STAGE RAW.IOT_STAGE
  URL = 's3://portfolio-iot-bucket/truck_telemetry/'
  STORAGE_INTEGRATION = s3_iot_integration
  FILE_FORMAT = RAW.JSON_FORMAT;

-- The Snowpipe. Tied to AWS SQS under the hood. Fires asynchronously when files land.
CREATE OR REPLACE PIPE RAW.TRUCK_TELEMETRY_PIPE
  AUTO_INGEST = TRUE
AS
  COPY INTO RAW.TRUCK_TELEMETRY_JSON (SRC_FILE_NAME, RAW_JSON)
  FROM (
      SELECT metadata$filename, $1 
      FROM @RAW.IOT_STAGE
  );

-----------------------------------------------------------------------------
-- 3. CHANGE DATA CAPTURE (STREAMS)
-----------------------------------------------------------------------------
-- This stream will act as a bookmark. It only shows records inserted since 
-- the stream was last DML'd against.
CREATE OR REPLACE STREAM RAW.TELEMETRY_STREAM 
  ON TABLE RAW.TRUCK_TELEMETRY_JSON
  APPEND_ONLY = TRUE;

-----------------------------------------------------------------------------
-- 4. PARSED DESTINATION & PIPELINE ORCHESTRATION (TASKS)
-----------------------------------------------------------------------------
-- Target relational table where analysis will actually happen.
CREATE OR REPLACE TABLE HARMONIZED.TRUCK_TELEMETRY_FLAT (
    EVENT_ID VARCHAR PRIMARY KEY,
    TRUCK_ID INT,
    SPEED_MPH NUMBER,
    ENGINE_TEMP FLOAT,
    LATITUDE FLOAT,
    LONGITUDE FLOAT,
    EVENT_TIMESTAMP TIMESTAMP_NTZ
);

-- Serverless Task: Checks the stream every minute. If data exists, parses JSON using 
-- dot notation and merges it into the target table, ensuring no duplicates.
CREATE OR REPLACE TASK HARMONIZED.PARSE_AND_MERGE_TELEMETRY
  SCHEDULE = '1 MINUTE'
  USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL' -- Serverless compute!
  WHEN SYSTEM$STREAM_HAS_DATA('RAW.TELEMETRY_STREAM')
AS
  MERGE INTO HARMONIZED.TRUCK_TELEMETRY_FLAT tgt
  USING (
      SELECT 
        RAW_JSON:event_id::VARCHAR AS EVENT_ID,
        RAW_JSON:truck_id::INT AS TRUCK_ID,
        RAW_JSON:metrics.speed::NUMBER AS SPEED_MPH,
        RAW_JSON:metrics.engine_temp::FLOAT AS ENGINE_TEMP,
        RAW_JSON:location.lat::FLOAT AS LATITUDE,
        RAW_JSON:location.lon::FLOAT AS LONGITUDE,
        RAW_JSON:timestamp::TIMESTAMP_NTZ AS EVENT_TIMESTAMP
      FROM RAW.TELEMETRY_STREAM
  ) src
  ON tgt.EVENT_ID = src.EVENT_ID
  WHEN MATCHED THEN
    UPDATE SET 
        tgt.SPEED_MPH = src.SPEED_MPH, 
        tgt.ENGINE_TEMP = src.ENGINE_TEMP,
        tgt.LATITUDE = src.LATITUDE,
        tgt.LONGITUDE = src.LONGITUDE
  WHEN NOT MATCHED THEN
    INSERT (EVENT_ID, TRUCK_ID, SPEED_MPH, ENGINE_TEMP, LATITUDE, LONGITUDE, EVENT_TIMESTAMP)
    VALUES (src.EVENT_ID, src.TRUCK_ID, src.SPEED_MPH, src.ENGINE_TEMP, src.LATITUDE, src.LONGITUDE, src.EVENT_TIMESTAMP);

-- Activate the pipeline
ALTER TASK HARMONIZED.PARSE_AND_MERGE_TELEMETRY RESUME;
