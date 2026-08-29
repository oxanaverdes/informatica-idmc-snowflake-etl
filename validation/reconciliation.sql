-- ============================================================
-- Customer ETL Reconciliation
-- ============================================================
--
-- Purpose:
--   Validate that every customer record extracted during one
--   specific ETL run is accounted for as either successfully
--   loaded or rejected.
--
--
-- ============================================================
-- SAMPLE ETL RUN
-- ============================================================
--
-- RUN_ID      = 20260829_020000
--
-- SOURCE      = 3
-- LOADED      = 2
-- REJECTED    = 1
-- DIFFERENCE  = 0
-- STATUS      = PASS
--
--
-- ============================================================
-- RECORDS PROCESSED
-- ============================================================
--
-- CUSTOMER        RESULT
-- --------------  --------
-- 1002 Maria      Valid
-- 1003 David      Valid
-- NULL Robert     Rejected
--
--
-- ============================================================
-- WHAT ARE WE VALIDATING?
-- ============================================================
--
-- The Oracle incremental extract returned 3 records:
--
--   1002 Maria  -> Valid
--   1003 David  -> Valid
--   NULL Robert -> Rejected because CUSTOMER_ID is missing
--
-- IDMC routes the records as follows:
--
--                     IDMC INPUT
--                      3 records
--                         |
--                  +------+------+
--                  |             |
--                  v             v
--                VALID         REJECT
--                  2             1
--                  |             |
--                  v             v
--          STG_CUSTOMER    STG_CUSTOMER_REJ
--
-- Both targets store the same RUN_ID so the records can be
-- reconciled for one specific ETL execution.
--
--
-- ============================================================
-- RECONCILIATION RULE
-- ============================================================
--
-- Every extracted record must be accounted for:
--
--   SOURCE = LOADED + REJECTED
--
-- For this run:
--
--   3 = 2 + 1
--
-- Difference calculation:
--
--   DIFFERENCE = SOURCE - (LOADED + REJECTED)
--
--   DIFFERENCE = 3 - (2 + 1)
--              = 0
--
-- Therefore:
--
--   STATUS = PASS
--
--
-- If DIFFERENCE = 0:
--     Reconciliation PASSES.
--
-- If DIFFERENCE <> 0:
--     Reconciliation FAILS and the missing or additional
--     records must be investigated.
--
--
-- ============================================================
-- RUN IDENTIFIER
-- ============================================================
--
-- Sample RUN_ID:
--
--   20260829_020000
--
-- STG_CUSTOMER and STG_CUSTOMER_REJ both contain RUN_ID.
--
-- This allows reconciliation to count only records belonging
-- to the current ETL run instead of counting historical data
-- from previous executions.
--
-- ============================================================


-- ============================================================
-- 1. COUNT SUCCESSFULLY LOADED RECORDS FOR THIS RUN
-- ============================================================
--
-- Expected sample result:
--
-- RUN_ID             LOADED_RECORDS
-- -----------------  --------------
-- 20260829_020000          2
--

SELECT
    RUN_ID,
    COUNT(*) AS LOADED_RECORDS
FROM STG_CUSTOMER
WHERE RUN_ID = '20260829_020000'
GROUP BY RUN_ID;


-- ============================================================
-- 2. COUNT REJECTED RECORDS FOR THIS RUN
-- ============================================================
--
-- Expected sample result:
--
-- RUN_ID             REJECTED_RECORDS
-- -----------------  ----------------
-- 20260829_020000           1
--

SELECT
    RUN_ID,
    COUNT(*) AS REJECTED_RECORDS
FROM STG_CUSTOMER_REJ
WHERE RUN_ID = '20260829_020000'
GROUP BY RUN_ID;


-- ============================================================
-- 3. PROCESSING SUMMARY FOR THIS RUN
-- ============================================================
--
-- Expected sample result:
--
-- RUN_ID             LOADED   REJECTED   TOTAL_PROCESSED
-- -----------------  ------   --------   ---------------
-- 20260829_020000       2         1             3
--

SELECT
    '20260829_020000' AS RUN_ID,

    (SELECT COUNT(*)
       FROM STG_CUSTOMER
      WHERE RUN_ID = '20260829_020000') AS LOADED_RECORDS,

    (SELECT COUNT(*)
       FROM STG_CUSTOMER_REJ
      WHERE RUN_ID = '20260829_020000') AS REJECTED_RECORDS,

    (SELECT COUNT(*)
       FROM STG_CUSTOMER
      WHERE RUN_ID = '20260829_020000')
    +
    (SELECT COUNT(*)
       FROM STG_CUSTOMER_REJ
      WHERE RUN_ID = '20260829_020000') AS TOTAL_PROCESSED;


-- ============================================================
-- 4. RECONCILIATION RESULT
-- ============================================================
--
-- SOURCE_RECORDS is set to 3 for this documented sample run.
--
-- In a full production implementation, SOURCE_RECORDS would
-- normally come from an ETL audit/control table populated by
-- the source extraction step.
--
-- Expected result:
--
-- RUN_ID             SOURCE   LOADED   REJECTED   DIFFERENCE   STATUS
-- -----------------  ------   ------   --------   ----------   ------
-- 20260829_020000       3        2         1           0        PASS
--

WITH RUN_COUNTS AS (
    SELECT
        '20260829_020000' AS RUN_ID,
        3 AS SOURCE_RECORDS,

        (SELECT COUNT(*)
           FROM STG_CUSTOMER
          WHERE RUN_ID = '20260829_020000') AS LOADED_RECORDS,

        (SELECT COUNT(*)
           FROM STG_CUSTOMER_REJ
          WHERE RUN_ID = '20260829_020000') AS REJECTED_RECORDS
)

SELECT
    RUN_ID,
    SOURCE_RECORDS,
    LOADED_RECORDS,
    REJECTED_RECORDS,

    SOURCE_RECORDS
      - (LOADED_RECORDS + REJECTED_RECORDS)
        AS DIFFERENCE,

    CASE
        WHEN SOURCE_RECORDS
             - (LOADED_RECORDS + REJECTED_RECORDS) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS STATUS

FROM RUN_COUNTS;


-- ============================================================
-- EXPECTED RECONCILIATION
-- ============================================================
--
-- RUN_ID                 = 20260829_020000
-- SOURCE RECORDS         = 3
-- LOADED RECORDS         = 2
-- REJECTED RECORDS       = 1
--
-- 2 + 1 = 3
--
-- DIFFERENCE             = 0
-- RECONCILIATION STATUS  = PASS
--
-- ============================================================
