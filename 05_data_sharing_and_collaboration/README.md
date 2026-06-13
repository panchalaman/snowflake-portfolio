# Secure Data Sharing & Collaboration

One of Snowflake's most revolutionary features is its **Data Sharing** capability. Moving away from traditional FTPs, APIs, and manual ETL extracts to share data with partners, Snowflake enables live, secure, read-only access to governed datasets without moving a single byte of data.

## The Scenario
Our organization needs to securely share curated fleet tracking data (the "Gold" layer) with a 3rd party maintenance partner ("AutoFix Inc."). 

## Key Enterprise Considerations Demonstrated
1. **Direct Data Sharing:** Sharing data directly to another Snowflake account.
2. **Secure Views:** We never share raw underlying tables. We only share Secure Views to prevent the consumer from seeing hidden metadata or bypassed logic using EXPLAIN plans.
3. **No Data Copying:** The consumer reads directly from our storage, meaning they always have real-time data, and we don't pay for data egress.

## Code Instructions
Review `data_share_setup.sql` to see how a Provider sets up a Secure Share, attaches the Secure Views, and grants consumption rights seamlessly.
