-- ============================================================
-- ETL Run Control Table
-- Target System: Snowflake
-- ============================================================
--
-- Purpose:
--   Store execution-level information for each ETL run so
--   source counts, loaded counts, rejected counts, timestamps,
--   reconciliation results, and status can be monitored.
--
-- This file creates the control table only.
--
-- Actual ETL run INSERT/UPDATE processing is implemented in:
--
--   update_etl_run_control.sql
--
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

    CREATED_TIMESTAMP     TIMESTAMP_NTZ
                          DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT PK_ETL_RUN_CONTROL
        PRIMARY KEY (RUN_ID)
);


-- ============================================================
-- SAMPLE ETL RUN
-- ============================================================
--
-- The following values are documentation only.
-- This file does NOT insert the sample record.
--
-- Actual INSERT/UPDATE logic is located in:
--
--   update_etl_run_control.sql
--
--
-- Example:
--
-- RUN_ID
--   20260829_020000
--
-- PROCESS_NAME
--   CUSTOMER_ORACLE_TO_SNOWFLAKE
--
-- START_TIMESTAMP
--   2026-08-29 02:00:00
--
-- END_TIMESTAMP
--   2026-08-29 02:05:00
--
-- LAST_RUN_TIMESTAMP
--   2026-08-15 00:00:00
--
-- SOURCE_COUNT
--   3
--
-- LOADED_COUNT
--   2
--
-- REJECTED_COUNT
--   1
--
-- DIFFERENCE_COUNT
--   0
--
-- STATUS
--   PASS
--
--
-- Expected control record:
--
-- RUN_ID             SOURCE   LOADED   REJECTED   DIFFERENCE   STATUS
-- -----------------  ------   ------   --------   ----------   ------
-- 20260829_020000       3        2         1           0        PASS
--
-- ============================================================


-- ============================================================
-- HOW THIS TABLE IS USED
-- ============================================================
--
-- 1. ETL taskflow starts.
--
-- 2. A new row is inserted into ETL_RUN_CONTROL:
--
--      STATUS = 'RUNNING'
--
-- 3. Oracle incremental extraction runs.
--
-- 4. IDMC loads:
--
--      STG_CUSTOMER
--      STG_CUSTOMER_REJ
--
-- 5. Reconciliation compares:
--
--      SOURCE_COUNT
--
--      LOADED_COUNT
--
--      REJECTED_COUNT
--
-- 6. Difference is calculated:
--
--      DIFFERENCE_COUNT
--          =
--      SOURCE_COUNT
--          -
--      (LOADED_COUNT + REJECTED_COUNT)
--
-- 7. If DIFFERENCE_COUNT = 0:
--
--      STATUS = 'PASS'
--
-- 8. If DIFFERENCE_COUNT <> 0:
--
--      STATUS = 'FAIL'
--
-- 9. END_TIMESTAMP is populated.
--
--
-- ETL Flow:
--
--                 START
--                   |
--                   v
--        INSERT RUN CONTROL RECORD
--            STATUS = RUNNING
--                   |
--                   v
--          RUN IDMC PROCESSING
--                   |
--                   v
--            RECONCILIATION
--                   |
--             +-----+-----+
--             |           |
--             v           v
--            PASS        FAIL
--             |           |
--             v           v
--        STATUS=PASS  STATUS=FAIL
--             |           |
--             +-----+-----+
--                   |
--                   v
--           END_TIMESTAMP
--
-- ============================================================
