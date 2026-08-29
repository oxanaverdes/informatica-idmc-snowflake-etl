-- ============================================================
-- Customer Dimension - SCD Type 2 Processing
-- Target System: Snowflake
--
-- Purpose:
--   Preserve customer history when tracked attributes change.
--
-- Processing Rules:
--
--   NEW CUSTOMER
--     -> Insert a new current dimension record
--
--   CHANGED CUSTOMER
--     -> Close the existing current record
--     -> Insert a new current version
--
--   UNCHANGED CUSTOMER
--     -> No action
--
-- Assumption:
--   STG_CUSTOMER contains one validated record per CUSTOMER_ID
--   for the current ETL run.
-- ============================================================


-- ============================================================
-- STEP 1
-- Close existing current records when tracked attributes change.
-- ============================================================

UPDATE DIM_CUSTOMER tgt
SET
    EFFECTIVE_TO = CURRENT_TIMESTAMP(),
    IS_CURRENT   = FALSE
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


-- ============================================================
-- STEP 2
-- Insert:
--   1. Brand-new customers
--   2. New versions of customers closed in Step 1
--
-- Unchanged customers still have an active/current record and
-- therefore are not inserted again.
-- ============================================================

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


-- ============================================================
-- EXAMPLE
-- ============================================================
--
-- Existing DIM_CUSTOMER:
--
-- CUSTOMER_ID   STATE   IS_CURRENT
-- -----------   -----   ----------
-- 1002          IL      TRUE
--
-- Incoming STG_CUSTOMER:
--
-- CUSTOMER_ID   STATE
-- -----------   -----
-- 1002          IN
--
-- After SCD Type 2 processing:
--
-- CUSTOMER_ID   STATE   IS_CURRENT
-- -----------   -----   ----------
-- 1002          IL      FALSE
-- 1002          IN      TRUE
--
-- Customer history is preserved instead of overwriting IL.
-- ============================================================
