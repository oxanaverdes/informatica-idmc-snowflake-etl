-- ============================================================
-- Snowflake Customer Reject Table
-- Purpose:
--   Store customer records rejected during IDMC validation
--   so they can be investigated and reprocessed.
-- ============================================================

CREATE OR REPLACE TABLE STG_CUSTOMER_REJ (
    CUSTOMER_ID       NUMBER(10,0),
    FIRST_NAME        VARCHAR(50),
    LAST_NAME         VARCHAR(50),
    EMAIL             VARCHAR(100),
    STATE             VARCHAR(2),
    STATUS            VARCHAR(20),
    LAST_UPDATED      TIMESTAMP_NTZ,

    REJECT_REASON     VARCHAR(500),
    SOURCE_SYSTEM     VARCHAR(30) DEFAULT 'ORACLE',
    REJECT_TIMESTAMP  TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
