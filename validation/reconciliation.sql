-- ============================================================
-- Customer ETL Reconciliation
-- ============================================================
--
-- Purpose:
--   Reconcile one ETL execution using RUN_ID and validate that
--   every extracted source record is accounted for as either
--   successfully loaded or rejected.
--
-- Sample RUN_ID:
--
--   20260829_020000
--
-- Expected result:
--
-- SOURCE      = 3
-- LOADED      = 2
-- REJECTED    = 1
-- DIFFERENCE  = 0
-- STATUS      = PASS
--
-- ============================================================


-- ============================================================
-- 1. LOADED RECORDS FOR THE RUN
-- ============================================================

SELECT
    RUN_ID,
    COUNT(*) AS LOADED_RECORDS
FROM STG_CUSTOMER
WHERE RUN_ID = '20260829_020000'
GROUP BY RUN_ID;


-- ============================================================
-- 2. REJECTED RECORDS FOR THE RUN
-- ============================================================

SELECT
    RUN_ID,
    COUNT(*) AS REJECTED_RECORDS
FROM STG_CUSTOMER_REJ
WHERE RUN_ID = '20260829_020000'
GROUP BY RUN_ID;


-- ============================================================
-- 3. RECONCILIATION
-- ============================================================
--
-- SOURCE_COUNT comes from ETL_RUN_CONTROL.
--
-- Loaded and rejected counts come from the staging tables
-- using the same RUN_ID.
--
-- Reconciliation Rule:
--
--   SOURCE_COUNT = LOADED_COUNT + REJECTED_COUNT
--
-- Difference:
--
--   SOURCE_COUNT - (LOADED_COUNT + REJECTED_COUNT)
--
-- If DIFFERENCE = 0 -> PASS
-- Otherwise          -> FAIL
--
-- ============================================================

WITH RUN_DATA AS (

    SELECT
        ctl.RUN_ID,
        ctl.SOURCE_COUNT,

        (
            SELECT COUNT(*)
            FROM STG_CUSTOMER stg
            WHERE stg.RUN_ID = ctl.RUN_ID
        ) AS LOADED_COUNT,

        (
            SELECT COUNT(*)
            FROM STG_CUSTOMER_REJ rej
            WHERE rej.RUN_ID = ctl.RUN_ID
        ) AS REJECTED_COUNT

    FROM ETL_RUN_CONTROL ctl

    WHERE ctl.RUN_ID = '20260829_020000'
)

SELECT
    RUN_ID,
    SOURCE_COUNT,
    LOADED_COUNT,
    REJECTED_COUNT,

    SOURCE_COUNT
        - (LOADED_COUNT + REJECTED_COUNT)
        AS DIFFERENCE,

    CASE
        WHEN SOURCE_COUNT
             - (LOADED_COUNT + REJECTED_COUNT) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS STATUS

FROM RUN_DATA;


-- ============================================================
-- EXPECTED SAMPLE RESULT
-- ============================================================
--
-- RUN_ID             SOURCE   LOADED   REJECTED   DIFFERENCE   STATUS
-- -----------------  ------   ------   --------   ----------   ------
-- 20260829_020000       3        2         1           0        PASS
--
--
-- Records represented by this run:
--
-- CUSTOMER        RESULT
-- --------------  --------
-- 1002 Maria      Loaded
-- 1003 David      Loaded
-- NULL Robert     Rejected
--
--
-- Data Flow:
--
--                SOURCE COUNT
--                     3
--                     |
--              +------+------+
--              |             |
--              v             v
--           LOADED         REJECTED
--              2              1
--              |              |
--              +------+-------+
--                     |
--                     v
--                  2 + 1
--                     |
--                     v
--                     3
--                     |
--                     v
--              DIFFERENCE = 0
--                     |
--                     v
--                   PASS
--
-- ============================================================


-- ============================================================
-- 4. COMPARE STORED CONTROL VALUES TO ACTUAL COUNTS
-- ============================================================
--
-- This check compares the counts stored in ETL_RUN_CONTROL
-- against the actual rows found in the staging tables.
--
-- Expected:
--
-- STORED_LOADED   = ACTUAL_LOADED
-- STORED_REJECTED = ACTUAL_REJECTED
--
-- ============================================================

SELECT
    ctl.RUN_ID,

    ctl.SOURCE_COUNT,

    ctl.LOADED_COUNT AS STORED_LOADED_COUNT,

    (
        SELECT COUNT(*)
        FROM STG_CUSTOMER stg
        WHERE stg.RUN_ID = ctl.RUN_ID
    ) AS ACTUAL_LOADED_COUNT,

    ctl.REJECTED_COUNT AS STORED_REJECTED_COUNT,

    (
        SELECT COUNT(*)
        FROM STG_CUSTOMER_REJ rej
        WHERE rej.RUN_ID = ctl.RUN_ID
    ) AS ACTUAL_REJECTED_COUNT,

    ctl.DIFFERENCE_COUNT,

    ctl.STATUS

FROM ETL_RUN_CONTROL ctl

WHERE ctl.RUN_ID = '20260829_020000';


-- ============================================================
-- EXPECTED CONTROL VALIDATION
-- ============================================================
--
-- RUN_ID              = 20260829_020000
--
-- SOURCE_COUNT        = 3
--
-- STORED_LOADED       = 2
-- ACTUAL_LOADED       = 2
--
-- STORED_REJECTED     = 1
-- ACTUAL_REJECTED     = 1
--
-- DIFFERENCE_COUNT    = 0
-- STATUS              = PASS
--
-- ============================================================
