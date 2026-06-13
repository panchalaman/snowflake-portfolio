# Streaming and Continuous Pipelining

In modern Data Engineering, batch loading overnight is often insufficient for competitive business operations. This module demonstrates setting up a **Continuous Ingestion and Transformation Pipeline**.

## The Scenario
Imagine IoT sensors from delivery trucks continuously dropping JSON diagnostic files (engine temp, coordinates, speed) into an AWS S3 bucket throughout the day. We need to parse these down to flat, relational structures in near-real-time without writing and managing complex Airflow DAGs.

## The Snowflake Solution

1. **Snowpipe**
   * Designed to listen to an S3 event queue (Amazon SQS). Whenever a file lands, Snowpipe wakes up and executes a `COPY INTO` command automatically. 
   * **Why it matters:** It charges only per second of compute specifically used for the file size, rather than spinning up a Virtual Warehouse for a minimum 60-second window.

2. **Streams (Offset Tracking)**
   * We attach a native Snowflake `STREAM` object to the raw landing table. 
   * **Why it matters:** It automatically tracks exactly which rows are new (inserts/updates/deletes) since the last time a downstream process consumed them. We completely eliminate the need for complex "high-water mark" tracking columns.

3. **Serverless Tasks**
   * A `TASK` is scheduled to check the stream every minute. If there is data, it processes it.
   * **Why it matters:** We configure it as `SERVERLESS`. Snowflake manages the compute sizing under the hood dynamically, removing the need to provision dedicated Warehouses for simple continuous tasks.

## Code Instructions
Review `streaming_cdc_pipeline.sql` to see the full implementation from the JSON-landing table down to the fully parsed and deduplicated relational table.
