# Snowpark and Compute Push-Down

Traditionally, Machine Learning and complex data science required massive data movement: Spark or local Python environments pulling massive datasets out of the Data Warehouse, running their models, and pushing the results back. This is slow, inherently insecure, and operationally fragmented.

## The Paradigm: "Bring the Code to the Data"
**Snowpark** allows Data Scientists and Engineers to write Python (or Scala/Java) natively, utilizing familiar APIs like DataFrames or native Pandas formats.
Crucially, **the data never leaves Snowflake**. The code is wrapped, packaged, and executed inside identical secure sandboxes running inside snowflake's elastic virtual compute nodes.

This folder highlights the capability to convert typical Python functions into Serverless logic units immediately accessible to standard SQL queries.

## Components Demonstrated
1. **Python User Defined Functions (UDF):** Embedding complex regex or data enrichment logic seamlessly inside a SQL select statement.
2. **Snowpark Stored Procedures:** Fetching data via Snowpark DataFrames natively inside Snowflake, running high-scale predictive transformations.

## Code Instructions
Review `snowpark_feature_engineering.sql` to observe how Python interoperates flawlessly with Snowflake's SQL engine.
