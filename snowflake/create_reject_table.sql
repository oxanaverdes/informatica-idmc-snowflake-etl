--   Store the complete source record when customer data is
--   rejected during IDMC validation so the record can be
--   investigated, corrected, and reprocessed.

CREATE OR REPLACE TABLE STG_CUSTOMER_REJ (
    CUSTOMER_ID       NUMBER(10,0),
    FIRST_NAME        VARCHAR(50),
    LAST_NAME         VARCHAR(50),
    EMAIL             VARCHAR(100),
    STATE             VARCHAR(2),
    STATUS            VARCHAR(20),
    CREATED_DATE      DATE,
    LAST_UPDATED      TIMESTAMP_NTZ,

    REJECT_REASON     VARCHAR(500),
    SOURCE_SYSTEM     VARCHAR(30) DEFAULT 'ORACLE',
    REJECT_TIMESTAMP  TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
