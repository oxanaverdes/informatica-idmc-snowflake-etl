-- ============================================================
-- Incremental Customer Extract
-- Source System: Oracle
-- Purpose:
--   Extract only new or updated customer records
--   since the last successful ETL run.
-- ============================================================

SELECT
    CUSTOMER_ID,
    FIRST_NAME,
    LAST_NAME,
    EMAIL,
    STATE,
    STATUS,
    CREATED_DATE,
    LAST_UPDATED
FROM CUSTOMER
WHERE LAST_UPDATED > TO_TIMESTAMP(
    '${LAST_RUN_TIMESTAMP}',
    'YYYY-MM-DD HH24:MI:SS'
)
ORDER BY LAST_UPDATED;
