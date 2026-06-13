# Enterprise Data Architecture Design

In this portfolio, the architectural paradigm closely follows the **Medallion Architecture** (Bronze, Silver, Gold layers) physically mapped onto Snowflake databases and schemas.

## The Logical Layers

### 1. RAW (Bronze Layer)
* **Purpose:** Landing zone for all external data. Exactly mimics source system schemas.
* **Snowflake Implementation:**
  * Uses `VARIANT` column types heavily for semi-structured data (JSON, Parquet) without requiring upfront schema definitions (Schema-on-Read).
  * Ingestion relies entirely on **Snowpipe** (for file-based S3/Azure/GCP lands) or the **Snowpipe Streaming API** (for low-latency Kafka/event streams).
* **Governance:** Extremely restricted read access. Only automation pipelines and top-level Data Engineers can access this area to prevent exposure of completely unmasked PII.

### 2. HARMONIZED (Silver Layer)
* **Purpose:** Cleansed, flattened, typed, and integrated data. Slowly Changing Dimensions (SCD Type 2) or basic Deduplication is applied here.
* **Snowflake Implementation:**
  * Utilizes **Streams on Tables** to capture Change Data Capture (CDC) events moving from RAW.
  * Uses orchestrated **Tasks** to execute `MERGE` statements gracefully handling UPSERTs.
  * Data masking policies are often applied at this layer using Snowflake Object Tagging so that any downstream consumers inherit the masked views automatically.

### 3. ANALYTICS (Gold Layer)
* **Purpose:** Business-ready dimensional models, aggregations, and feature tables for ML.
* **Snowflake Implementation:**
  * Heavy reliance on **Dynamic Tables** to build continuous materializations simply by writing `SELECT` statements, eliminating complex DAGs for final aggregations.
  * **Secure Views** and **Row Access Policies** are applied to ensure multi-tenant or multi-department segregation (e.g., Regional Managers only see their region's sales).

## Key Architectural Decisions & Trade-offs

### Streams and Tasks vs. Dynamic Tables
* **Why did I use both in this portfolio?**
  * **Dynamic Tables (DTs)** are amazing for declarative mapping (Gold layer aggregates), but they lack precise control over *how* DML operations act if there is complex custom collision logic heavily reliant on external state.
  * **Streams & Tasks** are imperative. I use these transitioning from RAW to HARMONIZED because it provides granular control over metadata columns (e.g., insertion timestamps vs update timestamps) and complex SCD Type 2 logic where history tracking is paramount.

### Data Governance Strategy
* **Role-Based Access Control (RBAC):** Every object is owned by a functional role (e.g., `DATA_ENG_ROLE`), not a user. Read/Write grants are passed down through a role hierarchy.
* **Dynamic over Static Masking:** Rather than creating multiple views for different users (a maintenance nightmare), I utilized Dynamic Data Masking policies. A single table exists, but the query engine replaces PII with hash strings instantly if the executing context isn't an `HR_ROLE` or `EXEC_ROLE`.

### Compute Isolation
* Workloads are strictly isolated to dedicated Virtual Warehouses to ensure zero resource contention:
  * `INGESTION_WH`: Optimized for high concurrency, low complexity. Auto-scales.
  * `TRANSFORMATION_WH`: High memory, low concurrency.
  * `REPORTING_WH`: High concurrency, multi-cluster enabled for BI dashboards.
