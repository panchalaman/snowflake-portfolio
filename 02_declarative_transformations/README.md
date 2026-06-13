# Declarative Transformations with Dynamic Tables

As data flows into the silver/harmonized layers, it typically needs to be heavily joined, aggregated, and flattened into "Gold" datasets for Business Intelligence consumption. 

## The Old Way: Imperative Processing
Historically, engineers had to write a `TASK` mapping to a stored procedure or an orchestration tool (like Apache Airflow) that would:
1. `TRUNCATE` and `INSERT` an entire aggregation table nightly (painfully slow and expensive).
2. Or build complex `MERGE` logic wrapped in tasks using `STREAMS`. While performant, maintaining a web of dependent Tasks and nested queries becomes an operational nightmare.

## The Modern Alternative: Dynamic Tables
**Dynamic Tables** represent a paradigm shift to **Declarative Engineering**. 
Instead of defining *how* the data should update, you simply write a `SELECT` statement and define a **target lag** (e.g., "I want this data to reflect upstream changes no older than 1 hour").

Snowflake’s automated compute engine handles the rest:
- Tracking dependencies natively.
- Performing micro-incremental updates under the hood, updating *only* the aggregates that changed rather than recalculating the whole table.
- Significantly lowering maintenance and pipeline logic logic complexity.

## Code Instructions
Review `dynamic_tables.sql` to see how a complex analytical aggregation tier is built natively, automatically chained, and inherently incrementally refreshed.
