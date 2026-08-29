-- ============================================================
-- ETL Run Control Table
-- Target System: Snowflake
--
-- Purpose:
--   Store execution-level information for each ETL run so
--   source counts, load counts, reject counts, timestamps,
--   reconciliation results, and status can be monitored.
-- ============================================================

CREATE OR REPLACE TABLE ETL_RUN_CONTROL (
    RUN_ID                VARCHAR(30) NOT NULL,

    PROCESS_NAME          VARCHAR(100),

    START_TIMESTAMP       TIMESTAMP_NTZ,
    END_TIMESTAMP         TIMESTAMP_NTZ,

    LAST_RUN_TIMESTAMP    TIMESTAMP_NTZ,

    SOURCE_COUNT          NUMBER(10,0),
    LOADED_COUNT          NUMBER(10,0),
    REJECTED_COUNT        NUMBER(10,0),

    DIFFERENCE_COUNT      NUMBER(10,0),

    STATUS                VARCHAR(20),

    ERROR_MESSAGE         VARCHAR(1000),

    CREATED_TIMESTAMP     TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT PK_ETL_RUN_CONTROL PRIMARY KEY (RUN_ID)
);


-- ============================================================
-- SAMPLE RUN
-- ============================================================
--
-- RUN_ID             = 20260829_020000
-- PROCESS_NAME       = CUSTOMER_ORACLE_TO_SNOWFLAKE
-- LAST_RUN_TIMESTAMP = 2026-08-15 00:00:00
--
-- SOURCE_COUNT       = 3
-- LOADED_COUNT       = 2
-- REJECTED_COUNT     = 1
-- DIFFERENCE_COUNT   = 0
-- STATUS             = PASS
--
-- ============================================================


INSERT INTO ETL_RUN_CONTROL (
    RUN_ID,
    PROCESS_NAME,
    START_TIMESTAMP,
    END_TIMESTAMP,
    LAST_RUN_TIMESTAMP,
    SOURCE_COUNT,
    LOADED_COUNT,
    REJECTED_COUNT,
    DIFFERENCE_COUNT,
    STATUS,
    ERROR_MESSAGE
)
VALUES (
    '20260829_020000',
    'CUSTOMER_ORACLE_TO_SNOWFLAKE',
    '2026-08-29 02:00:00',
    '2026-08-29 02:05:00',
    '2026-08-15 00:00:00',
    3,
    2,
    1,
    0,
    'PASS',
    NULL
);
