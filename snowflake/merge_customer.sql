-- ============================================================
-- Customer Dimension - SCD Type 2 Processing
-- Target System: Snowflake
-- Purpose:
--   Preserve customer history when tracked attributes change.
-- ============================================================

-- Step 1:
-- Close the current dimension record when customer attributes
-- have changed in staging.

UPDATE DIM_CUSTOMER tgt
SET
    EFFECTIVE_TO = CURRENT_TIMESTAMP(),
    IS_CURRENT = FALSE
FROM STG_CUSTOMER src
WHERE tgt.CUSTOMER_ID = src.CUSTOMER_ID
  AND tgt.IS_CURRENT = TRUE
  AND (
       COALESCE(tgt.FIRST_NAME, '') <> COALESCE(src.FIRST_NAME, '')
    OR COALESCE(tgt.LAST_NAME, '')  <> COALESCE(src.LAST_NAME, '')
    OR COALESCE(tgt.EMAIL, '')      <> COALESCE(src.EMAIL, '')
    OR COALESCE(tgt.STATE, '')      <> COALESCE(src.STATE, '')
    OR COALESCE(tgt.STATUS, '')     <> COALESCE(src.STATUS, '')
  );


-- Step 2:
-- Insert new customers and new versions of customers whose
-- information changed.

INSERT INTO DIM_CUSTOMER (
    CUSTOMER_ID,
    FIRST_NAME,
    LAST_NAME,
    EMAIL,
    STATE,
    STATUS,
    EFFECTIVE_FROM,
    EFFECTIVE_TO,
    IS_CURRENT
)
SELECT
    src.CUSTOMER_ID,
    src.FIRST_NAME,
    src.LAST_NAME,
    src.EMAIL,
    src.STATE,
    src.STATUS,
    CURRENT_TIMESTAMP(),
    NULL,
    TRUE
FROM STG_CUSTOMER src
LEFT JOIN DIM_CUSTOMER tgt
    ON src.CUSTOMER_ID = tgt.CUSTOMER_ID
   AND tgt.IS_CURRENT = TRUE
WHERE tgt.CUSTOMER_ID IS NULL;
