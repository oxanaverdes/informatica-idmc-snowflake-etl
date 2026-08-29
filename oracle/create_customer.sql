-- ============================================================
-- Customer Source Table
-- Source System: Oracle
-- Purpose:
--   Simulates an operational customer table used as the source
--   for an Informatica IDMC incremental ETL pipeline.
-- ============================================================

CREATE TABLE CUSTOMER (
    CUSTOMER_ID     NUMBER(10)      NOT NULL,
    FIRST_NAME      VARCHAR2(50),
    LAST_NAME       VARCHAR2(50),
    EMAIL           VARCHAR2(100),
    STATE           VARCHAR2(2),
    STATUS          VARCHAR2(20),
    CREATED_DATE    DATE,
    LAST_UPDATED    TIMESTAMP,

    CONSTRAINT PK_CUSTOMER PRIMARY KEY (CUSTOMER_ID)
);
