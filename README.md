# ❄️ Snowflake Data Engineering Portfolio

Welcome to my professional Data Engineering portfolio. I am a **Certified Snowflake Data Engineer**, and this repository serves as a comprehensive demonstration of my ability to design, build, and optimize enterprise-grade data platforms on the Snowflake Data Cloud.

## 🎯 Objective
This repository goes beyond simple syntax. It is engineered to demonstrate **architectural decision-making**, **cost-optimization**, **security-first design**, and **scalable pipeline orchestration**. Whether you are a technical recruiter, hiring manager, or principal engineer, this portfolio is structured to give you absolute confidence in my ability to deliver immediate value to your data organization.

## 🏆 Certifications
* **SnowPro Certified Data Engineer**
* Demonstrated proficiency in:
  * Real-time and batch data ingestion (Snowpipe, Snowpipe Streaming)
  * Complex data transformations (Streams, Tasks, Dynamic Tables)
  * Data Governance & Security (RBAC, Masking Policies, Object Tagging)
  * Snowpark (Python) and Performance Tuning

## 📂 Repository Structure

The portfolio is divided into distinct, real-world architectural patterns. Each module contains not only the code but a `README.md` detailing the **"Why"** behind the technical choices.

1. [**Architecture & System Design**](ARCHITECTURE_DESIGN.md) - High-level overview of the Medallion architecture applied in Snowflake.
2. [**01_streaming_and_continuous_pipelines**](01_streaming_and_continuous_pipelines/) - Real-time JSON ingestion using Snowpipe, Streams, and Serverless Tasks.
3. [**02_declarative_transformations**](02_declarative_transformations/) - Modern micro-batch processing using Dynamic Tables to reduce orchestration overhead.
4. [**03_data_governance_and_security**](03_data_governance_and_security/) - Enterprise access control using Tag-based Masking, Row Access Policies, and strict RBAC.
5. [**04_snowpark_data_science**](04_snowpark_data_science/) - Pushing compute down to the data using Snowpark Python for feature engineering and UDFs.
6. [**05_data_sharing_and_collaboration**](05_data_sharing_and_collaboration/) - B2B/B2B secure data sharing without ETL, using Secure Views and Direct Shares.
7. [**06_cost_management_and_finops**](06_cost_management_and_finops/) - Configuring Resource Monitors, auto-suspend architectures, and safeguarding cloud spend.

## 🛠️ Infrastructure & DevOps (CI/CD)
To prove proficiency working within a modern developer ecosystem, this repository includes a `.github/workflows/snowflake_deploy.yml` pipeline. This demonstrates a **schema-as-code** methodology, utilizing GitHub actions and tools like `schemachange` (or Flyway) to perform automated database deployments.

## 💡 Engineering Philosophy
* **Infrastructure as Code (IaC) readiness:** All SQL scripts are written to be easily integrated into CI/CD pipelines (e.g., Flyway, or dbt).
* **Cost Efficiency:** Serverless features (Tasks, Snowpipe) are utilized optimally. Virtual Warehouses are rightsized with auto-suspend.
* **Declarative over Imperative:** Favoring Dynamic Tables where state management can be offloaded to Snowflake's system engine to reduce operational burdens.

---
*Thank you for reviewing my work. I look forward to discussing how these patterns can solve challenges in your data ecosystem.*
