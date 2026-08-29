-- ============================================================
-- Snowflake Customer Dimension
-- Target System: Snowflake
-- Purpose:
--   Stores customer history using a Type 2 Slowly Changing
--   Dimension pattern.
-- ============================================================

CREATE OR REPLACE TABLE DIM_CUSTOMER (
    CUSTOMER_SK      NUMBER AUTOINCREMENT START 1 INCREMENT 1,
    CUSTOMER_ID      NUMBER(10,0) NOT NULL,
    FIRST_NAME       VARCHAR(50),
    LAST_NAME        VARCHAR(50),
    EMAIL            VARCHAR(100),
    STATE            VARCHAR(2),
    STATUS           VARCHAR(20),

    EFFECTIVE_FROM   TIMESTAMP_NTZ,
    EFFECTIVE_TO     TIMESTAMP_NTZ,
    IS_CURRENT       BOOLEAN,

    LOAD_TIMESTAMP   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT PK_DIM_CUSTOMER PRIMARY KEY (CUSTOMER_SK)
);
