-- ============================================================
-- Customer Data Quality Checks
-- Purpose:
--   Validate customer records after they are loaded into
--   Snowflake staging.
-- ============================================================


-- ============================================================
-- TEST 1: CUSTOMER_ID must not be NULL
-- Expected result: 0
-- ============================================================

SELECT COUNT(*) AS NULL_CUSTOMER_ID_COUNT
FROM STG_CUSTOMER
WHERE CUSTOMER_ID IS NULL;


-- ============================================================
-- TEST 2: STATE must be uppercase
-- Expected result: 0
-- ============================================================

SELECT COUNT(*) AS INVALID_STATE_CASE_COUNT
FROM STG_CUSTOMER
WHERE STATE <> UPPER(STATE);


-- ============================================================
-- TEST 3: STATUS must be standardized
-- Expected result: 0
-- ============================================================

SELECT COUNT(*) AS INVALID_STATUS_COUNT
FROM STG_CUSTOMER
WHERE STATUS NOT IN ('ACTIVE', 'INACTIVE');


-- ============================================================
-- TEST 4: CUSTOMER_ID should be unique in staging
-- Expected result: no rows returned
-- ============================================================

SELECT
    CUSTOMER_ID,
    COUNT(*) AS RECORD_COUNT
FROM STG_CUSTOMER
GROUP BY CUSTOMER_ID
HAVING COUNT(*) > 1;


-- ============================================================
-- TEST 5: Reject records should contain a reason
-- Expected result: 0
-- ============================================================

SELECT COUNT(*) AS MISSING_REJECT_REASON_COUNT
FROM STG_CUSTOMER_REJ
WHERE REJECT_REASON IS NULL
   OR TRIM(REJECT_REASON) = '';


-- ============================================================
-- EXPECTED TEST RESULTS
-- ============================================================
--
-- NULL_CUSTOMER_ID_COUNT      = 0   PASS
-- INVALID_STATE_CASE_COUNT    = 0   PASS
-- INVALID_STATUS_COUNT        = 0   PASS
-- DUPLICATE CUSTOMER_ID       = none PASS
-- MISSING_REJECT_REASON_COUNT = 0   PASS
--
-- If any check returns unexpected records/counts,
-- the ETL run should be investigated before downstream
-- processing is considered complete.
-- ============================================================
