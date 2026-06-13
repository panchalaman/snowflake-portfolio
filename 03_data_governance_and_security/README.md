# Advanced Data Governance

A key responsibility of a Lead/Senior Data Engineer goes beyond moving data—it’s securing it. With PII (Personally Identifiable Information) and strict regulatory requirements (GDPR, CCPA), architecture must treat security natively.

## Snowflake's Governance Primitives

Instead of building individual reporting views stripped of PII for different departments, Snowflake allows data to be governed dynamically at the column and row levels globally.

### 1. Object Tagging
Tags are key-value pairs (`PII: High`, `CostCenter: Marketing`) assigned to Snowflake objects (columns, tables, warehouses). This helps with auditing and dynamic security.

### 2. Tag-Based Dynamic Data Masking
This is a game-changer. Rather than applying a masking policy manually to every single table column containing sensitive data (which creates human-error gaps if a table slips through), we apply a **Masking Policy to a Tag**. 
When a column is tagged as `PII = 'TRUE'`, the data is inherently unreadable unless the executing user possesses the authorized functional role (e.g., `HR_DBA_ROLE`).

### 3. Row Access Policies
It dynamically filters out rows depending on who is querying the database. E.g., A regional manager for New York runs `SELECT * FROM GLOBAL_SALES` and only sees New York sales returned.

## Code Instructions
Review `governance_framework.sql` to witness a zero-trust governance model implemented in enterprise data objects.
