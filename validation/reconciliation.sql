-- ============================================================
-- Customer ETL Reconciliation
-- ============================================================
--
-- Purpose:
--   Validate that every customer record extracted during an
--   ETL run is accounted for as either successfully loaded
--   or rejected.
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
--
-- ============================================================
-- RECONCILIATION RULE
-- ============================================================
--
-- Every source record must be accounted for:
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
-- PRODUCTION NOTE
-- ============================================================
--
-- RUN_ID = 20260829_020000 is used here as a sample ETL run.
--
-- In a production implementation, each ETL execution should
-- have its own RUN_ID. The RUN_ID can be stored with staging,
-- rejected, and audit records so that reconciliation is
-- performed for one specific ETL execution rather than
-- against all historical records in the tables.
--
-- Example production audit result:
--
-- RUN_ID             SOURCE   LOADED   REJECTED   DIFFERENCE   STATUS
-- -----------------  ------   ------   --------   ----------   ------
-- 20260829_020000       3        2         1           0        PASS
--
-- ============================================================


-- ============================================================
-- 1. COUNT SUCCESSFULLY LOADED RECORDS
-- ============================================================
--
-- Expected sample result:
--
-- LOADED_RECORDS
-- --------------
--       2
--

SELECT
    COUNT(*) AS LOADED_RECORDS
FROM STG_CUSTOMER;


-- ============================================================
-- 2. COUNT REJECTED RECORDS
-- ============================================================
--
-- Expected sample result:
--
-- REJECTED_RECORDS
-- ----------------
--        1
--

SELECT
    COUNT(*) AS REJECTED_RECORDS
FROM STG_CUSTOMER_REJ;


-- ============================================================
-- 3. PROCESSING SUMMARY
-- ============================================================
--
-- Expected sample result:
--
-- LOADED_RECORDS   REJECTED_RECORDS   TOTAL_PROCESSED
-- --------------   ----------------   ---------------
--       2                  1                 3
--

SELECT
    (SELECT COUNT(*)
       FROM STG_CUSTOMER) AS LOADED_RECORDS,

    (SELECT COUNT(*)
       FROM STG_CUSTOMER_REJ) AS REJECTED_RECORDS,

    (SELECT COUNT(*)
       FROM STG_CUSTOMER)
    +
    (SELECT COUNT(*)
       FROM STG_CUSTOMER_REJ) AS TOTAL_PROCESSED;


-- ============================================================
-- EXPECTED RECONCILIATION
-- ============================================================
--
-- SOURCE RECORDS        = 3
-- LOADED RECORDS        = 2
-- REJECTED RECORDS      = 1
--
-- 2 + 1 = 3
--
-- DIFFERENCE            = 0
-- RECONCILIATION STATUS = PASS
--
-- ============================================================
