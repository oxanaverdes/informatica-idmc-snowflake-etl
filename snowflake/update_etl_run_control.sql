-- ============================================================
-- ETL Run Control Processing
-- Target System: Snowflake
-- ============================================================
--
-- Purpose:
--   Track the status and reconciliation results of each
--   customer ETL execution.
--
-- Sample RUN_ID:
--   20260829_020000
--
-- ============================================================


-- ============================================================
-- 1. START ETL RUN
-- ============================================================

INSERT INTO ETL_RUN_CONTROL (
    RUN_ID,
    PROCESS_NAME,
    START_TIMESTAMP,
    LAST_RUN_TIMESTAMP,
    STATUS
)
VALUES (
    '20260829_020000',
    'Customer_Oracle_To_Snowflake',
    CURRENT_TIMESTAMP(),
    '2026-08-15 00:00:00',
    'RUNNING'
);


-- ============================================================
-- 2. UPDATE SUCCESSFUL RUN
-- ============================================================
--
-- Sample result:
--
-- SOURCE_COUNT   = 3
-- LOADED_COUNT   = 2
-- REJECTED_COUNT = 1
-- DIFFERENCE     = 0
-- STATUS         = PASS
--

UPDATE ETL_RUN_CONTROL
SET
    END_TIMESTAMP = CURRENT_TIMESTAMP(),
    SOURCE_COUNT = 3,
    LOADED_COUNT = 2,
    REJECTED_COUNT = 1,
    DIFFERENCE_COUNT = 3 - (2 + 1),
    STATUS = CASE
                WHEN 3 - (2 + 1) = 0 THEN 'PASS'
                ELSE 'FAIL'
             END
WHERE RUN_ID = '20260829_020000';


-- ============================================================
-- 3. VIEW ETL RUN RESULT
-- ============================================================

SELECT
    RUN_ID,
    PROCESS_NAME,
    START_TIMESTAMP,
    END_TIMESTAMP,
    LAST_RUN_TIMESTAMP,
    SOURCE_COUNT,
    LOADED_COUNT,
    REJECTED_COUNT,
    DIFFERENCE_COUNT,
    STATUS
FROM ETL_RUN_CONTROL
WHERE RUN_ID = '20260829_020000';
