-- ============================================================
-- Snowflake Customer Staging Table
-- Target System: Snowflake
-- Purpose:
--   Landing/staging table for customer records extracted
--   from Oracle and loaded through Informatica IDMC.
-- ============================================================

CREATE OR REPLACE TABLE STG_CUSTOMER (
    CUSTOMER_ID      NUMBER(10,0),
    FIRST_NAME       VARCHAR(50),
    LAST_NAME        VARCHAR(50),
    EMAIL            VARCHAR(100),
    STATE            VARCHAR(2),
    STATUS           VARCHAR(20),
    CREATED_DATE     DATE,
    LAST_UPDATED     TIMESTAMP_NTZ,

    -- ETL metadata
    LOAD_TIMESTAMP   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    SOURCE_SYSTEM    VARCHAR(30) DEFAULT 'ORACLE'
);
