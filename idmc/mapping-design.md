# Informatica IDMC Mapping Design

## Mapping

**Name:** `m_Load_Customer_To_Snowflake`

## Purpose

The mapping extracts new and updated customer records from Oracle, standardizes the incoming data, validates required fields, separates valid and rejected records, and loads the results into Snowflake staging tables.

The mapping uses incremental processing so that only customer records changed since the previous successful ETL run are processed.

---

## Data Flow

![Informatica IDMC Customer Mapping](../images/idmc-customer-mapping.png)

The mapping follows this processing flow:

```text
Oracle CUSTOMER
      |
      | Incremental Filter
      | LAST_UPDATED > LAST_RUN_TIMESTAMP
      v
IDMC Source
      |
      v
Expression
      |
      | Trim values
      | Standardize STATE
      | Standardize STATUS
      | Add SOURCE_SYSTEM
      | Add RUN_ID
      v
Data Validation
      |
      v
Router
     / \
    /   \
   v     v
VALID   REJECT
  |       |
  v       v
STG_    STG_CUSTOMER_REJ
CUSTOMER
```

---

# Mapping Walkthrough with Sample Data

The example below demonstrates how records change as they move through the IDMC mapping.

For this sample ETL execution:

```text
RUN_ID             = 20260829_020000
LAST_RUN_TIMESTAMP = 2026-08-15 00:00:00
```

---

## 1. Oracle Source

The source system is Oracle.

**Source table:** `CUSTOMER`

The sample source contains four customer records:

| CUSTOMER_ID | FIRST_NAME | LAST_NAME | EMAIL | STATE | STATUS | CREATED_DATE | LAST_UPDATED |
|---:|---|---|---|---|---|---|---|
| 1001 | John | Smith | john.smith@example.com | il | active | 2025-01-15 | 2026-08-10 |
| 1002 | Maria | Garcia | maria.garcia@example.com | in | active | 2025-03-22 | 2026-08-18 |
| 1003 | David | Brown | david.brown@example.com | oh | inactive | 2025-06-10 | 2026-08-20 |
| NULL | Robert | Davis | robert.davis@example.com | in | active | 2026-02-18 | 2026-08-21 |

**Source records = 4**

---

## 2. Incremental Extraction

The mapping does not process all Oracle records during every ETL execution.

Only records changed after the previous successful ETL run are extracted.

The previous successful timestamp is:

```text
LAST_RUN_TIMESTAMP = 2026-08-15 00:00:00
```

The incremental condition is:

```sql
WHERE LAST_UPDATED > :LAST_RUN_TIMESTAMP
```

The source records are evaluated as follows:

| Customer | LAST_UPDATED | Result | Reason |
|---|---|---|---|
| 1001 John | 2026-08-10 | Not Extracted | LAST_UPDATED is before 2026-08-15 |
| 1002 Maria | 2026-08-18 | Extracted | Changed after previous successful run |
| 1003 David | 2026-08-20 | Extracted | Changed after previous successful run |
| NULL Robert | 2026-08-21 | Extracted | Changed after previous successful run |

Customer `1001` is filtered out before entering the IDMC transformation flow.

Therefore:

```text
Oracle Source
4 records
    |
    | Incremental Filter
    v
IDMC Input
3 records
```

The IDMC mapping receives:

| CUSTOMER_ID | FIRST_NAME | LAST_NAME | STATE | STATUS | LAST_UPDATED |
|---:|---|---|---|---|---|
| 1002 | Maria | Garcia | in | active | 2026-08-18 |
| 1003 | David | Brown | oh | inactive | 2026-08-20 |
| NULL | Robert | Davis | in | active | 2026-08-21 |

**4 source records → 3 incremental records**

---

## 3. Source Transformation

The IDMC Source transformation reads the records returned by the Oracle incremental query.

At this point:

```text
Input records = 3
```

The Source transformation passes the extracted Oracle fields into the downstream Expression transformation.

Example fields include:

- `CUSTOMER_ID`
- `FIRST_NAME`
- `LAST_NAME`
- `EMAIL`
- `STATE`
- `STATUS`
- `CREATED_DATE`
- `LAST_UPDATED`

---

## 4. Expression Transformation

The Expression transformation standardizes incoming customer data and adds ETL metadata.

Example transformation logic:

```text
FIRST_NAME    = TRIM(FIRST_NAME)
LAST_NAME     = TRIM(LAST_NAME)
STATE         = UPPER(STATE)
STATUS        = UPPER(STATUS)
SOURCE_SYSTEM = 'ORACLE'
RUN_ID        = '20260829_020000'
```

### Before Expression

| CUSTOMER_ID | FIRST_NAME | STATE | STATUS |
|---:|---|---|---|
| 1002 | Maria | in | active |
| 1003 | David | oh | inactive |
| NULL | Robert | in | active |

### After Expression

| CUSTOMER_ID | FIRST_NAME | STATE | STATUS | SOURCE_SYSTEM | RUN_ID |
|---:|---|---|---|---|---|
| 1002 | Maria | **IN** | **ACTIVE** | ORACLE | 20260829_020000 |
| 1003 | David | **OH** | **INACTIVE** | ORACLE | 20260829_020000 |
| NULL | Robert | **IN** | **ACTIVE** | ORACLE | 20260829_020000 |

The Expression transformation therefore:

- removes unnecessary spaces
- standardizes state values
- standardizes status values
- identifies the source system
- associates each processed record with the current ETL `RUN_ID`

The record count remains:

```text
Input  = 3
Output = 3
```

No records should be removed by the Expression transformation.

---

## 5. Data Validation

The mapping validates required customer information before loading the records into the normal Snowflake staging table.

For this sample mapping, `CUSTOMER_ID` is required.

Validation logic:

```text
CUSTOMER_ID IS NOT NULL
```

The three records are evaluated as follows:

| CUSTOMER_ID | FIRST_NAME | Validation |
|---:|---|---|
| 1002 | Maria | PASS |
| 1003 | David | PASS |
| NULL | Robert | FAIL |

For rejected records, the mapping derives a reject reason.

Example:

```text
REJECT_REASON = 'Missing CUSTOMER_ID'
```

At this stage:

```text
Records evaluated  = 3
Valid candidates   = 2
Invalid candidates = 1
```

---

## 6. Router Transformation

The Router separates valid records from rejected records.

### VALID_RECORDS

Router condition:

```text
NOT ISNULL(CUSTOMER_ID)
```

Records routed to `VALID_RECORDS`:

| CUSTOMER_ID | FIRST_NAME | STATE | STATUS |
|---:|---|---|---|
| 1002 | Maria | IN | ACTIVE |
| 1003 | David | OH | INACTIVE |

These records continue to `STG_CUSTOMER`.

### REJECT_RECORDS

Router condition:

```text
ISNULL(CUSTOMER_ID)
```

Record routed to `REJECT_RECORDS`:

| CUSTOMER_ID | FIRST_NAME | STATE | STATUS | REJECT_REASON |
|---:|---|---|---|---|
| NULL | Robert | IN | ACTIVE | Missing CUSTOMER_ID |

This record continues to `STG_CUSTOMER_REJ`.

The Router result is:

```text
             IDMC INPUT
              3 records
                  |
           +------+------+
           |             |
           v             v
         VALID         REJECT
           2             1
           |             |
           v             v
    STG_CUSTOMER   STG_CUSTOMER_REJ
```

Therefore:

```text
3 input records = 2 valid + 1 rejected
```

---

## 7. Snowflake Valid Target

**Target system:** Snowflake

**Target table:** `STG_CUSTOMER`

The staging table contains records that successfully passed validation.

Expected output:

| CUSTOMER_ID | FIRST_NAME | LAST_NAME | EMAIL | STATE | STATUS | CREATED_DATE | LAST_UPDATED | RUN_ID | SOURCE_SYSTEM |
|---:|---|---|---|---|---|---|---|---|---|
| 1002 | Maria | Garcia | maria.garcia@example.com | IN | ACTIVE | 2025-03-22 | 2026-08-18 | 20260829_020000 | ORACLE |
| 1003 | David | Brown | david.brown@example.com | OH | INACTIVE | 2025-06-10 | 2026-08-20 | 20260829_020000 | ORACLE |

**Loaded records = 2**

The staging data is later used for dimensional processing, including SCD Type 2 processing into `DIM_CUSTOMER`.

---

## 8. Snowflake Reject Target

Rejected records are preserved instead of being silently discarded.

**Reject table:** `STG_CUSTOMER_REJ`

Expected rejected record:

| CUSTOMER_ID | FIRST_NAME | LAST_NAME | EMAIL | STATE | STATUS | CREATED_DATE | LAST_UPDATED | REJECT_REASON | RUN_ID | SOURCE_SYSTEM |
|---:|---|---|---|---|---|---|---|---|---|---|
| NULL | Robert | Davis | robert.davis@example.com | IN | ACTIVE | 2026-02-18 | 2026-08-21 | Missing CUSTOMER_ID | 20260829_020000 | ORACLE |

**Rejected records = 1**

Keeping the complete rejected source record makes it possible to:

- identify the failed record
- understand why it failed
- investigate the source data
- correct the problem
- reprocess the record if necessary

---

## 9. Why Four Source Records Become Three Output Records

The source file contains four records, but only three records satisfy the incremental condition.

```text
LAST_RUN_TIMESTAMP = 2026-08-15 00:00:00
```

The condition is:

```sql
LAST_UPDATED > :LAST_RUN_TIMESTAMP
```

Therefore:

```text
1001 John
LAST_UPDATED = 2026-08-10
2026-08-10 < 2026-08-15
→ NOT EXTRACTED


1002 Maria
LAST_UPDATED = 2026-08-18
2026-08-18 > 2026-08-15
→ EXTRACTED → VALID


1003 David
LAST_UPDATED = 2026-08-20
2026-08-20 > 2026-08-15
→ EXTRACTED → VALID


NULL Robert
LAST_UPDATED = 2026-08-21
2026-08-21 > 2026-08-15
→ EXTRACTED → REJECT
```

The complete count flow is:

```text
SOURCE FILE
4 records
    |
    | Incremental condition
    | LAST_UPDATED > LAST_RUN_TIMESTAMP
    |
    +---- 1001 John filtered out
    |
    v
EXTRACTED
3 records
    |
    v
IDMC
    |
 +--+--+
 |     |
 v     v
VALID REJECT
  2     1
 |       |
 v       v
STG_    STG_CUSTOMER_REJ
CUSTOMER
```

This is why:

```text
Source file records       = 4
Incrementally extracted   = 3
Loaded                    = 2
Rejected                  = 1
```

The source-to-target reconciliation is based on the **three records extracted for the ETL run**, not all four records present in the source table.

---

## 10. RUN_ID Tracking

The sample ETL execution uses:

```text
RUN_ID = 20260829_020000
```

`RUN_ID` is carried into both staging paths:

```text
                    RUN_ID
              20260829_020000
                     |
                 IDMC INPUT
                     |
              +------+------+
              |             |
              v             v
            VALID         REJECT
              |             |
              v             v
       STG_CUSTOMER   STG_CUSTOMER_REJ
              |             |
              +------+------+
                     |
              RUN_ID retained
```

This allows records to be associated with one specific ETL execution.

For example:

```sql
SELECT *
FROM STG_CUSTOMER
WHERE RUN_ID = '20260829_020000';
```

And:

```sql
SELECT *
FROM STG_CUSTOMER_REJ
WHERE RUN_ID = '20260829_020000';
```

This is useful for:

- reconciliation
- troubleshooting
- production monitoring
- root-cause analysis
- restart/reprocessing
- identifying records associated with a failed run

---

## 11. Reconciliation

After the mapping completes, all incrementally extracted records must be accounted for.

For this sample run:

```text
RUN_ID      = 20260829_020000

SOURCE      = 3
LOADED      = 2
REJECTED    = 1

DIFFERENCE  = 0
STATUS      = PASS
```

The reconciliation rule is:

```text
SOURCE = LOADED + REJECTED
```

Therefore:

```text
3 = 2 + 1
```

Difference:

```text
DIFFERENCE = SOURCE - (LOADED + REJECTED)

DIFFERENCE = 3 - (2 + 1)

DIFFERENCE = 0
```

Result:

```text
STATUS = PASS
```

Notice that `SOURCE = 3` represents the number of records returned by the **incremental extraction**, not the four total records stored in the Oracle source.

---

## 12. Mapping Result Summary

| Processing Step | Record Count |
|---|---:|
| Oracle source records | 4 |
| Filtered out by incremental logic | 1 |
| Incrementally extracted | 3 |
| Expression output | 3 |
| Valid records | 2 |
| Rejected records | 1 |
| Loaded to STG_CUSTOMER | 2 |
| Loaded to STG_CUSTOMER_REJ | 1 |
| Reconciliation difference | 0 |
| Reconciliation status | PASS |

The complete processing result is:

```text
4 source records
       |
       | 1 filtered out
       v
3 incremental records
       |
       v
IDMC Mapping
      / \
     /   \
    v     v
 VALID   REJECT
   2       1
   |       |
   v       v
 STG     STG_REJ

2 + 1 = 3

PASS
```

---

## 13. Mapping Responsibilities

The mapping demonstrates the following ETL responsibilities:

- reading Oracle source data
- incremental extraction using `LAST_UPDATED`
- passing only changed records into IDMC
- standardizing incoming values
- validating required fields
- routing valid and rejected records
- preserving rejected source data
- loading valid records into Snowflake staging
- loading invalid records into a Snowflake reject table
- assigning a `RUN_ID` to processed records
- supporting downstream reconciliation
- supporting troubleshooting and root-cause analysis

---

## 14. Related Repository Files

The files below contain the SQL, sample data, validation logic, and orchestration design used by this project.

### Oracle

- [Source Table Definition — create_customer.sql](../oracle/create_customer.sql)
- [Incremental Extraction — incremental_extract.sql](../oracle/incremental_extract.sql)

### Snowflake

- [Customer Staging Table — create_stage_tables.sql](../snowflake/create_stage_tables.sql)
- [Customer Reject Table — create_reject_table.sql](../snowflake/create_reject_table.sql)
- [Customer Dimension — create_dimension.sql](../snowflake/create_dimension.sql)
- [SCD Type 2 Processing — merge_customer.sql](../snowflake/merge_customer.sql)
- [ETL Run Control Table — create_etl_run_control.sql](../snowflake/create_etl_run_control.sql)
- [ETL Run Control Processing — update_etl_run_control.sql](../snowflake/update_etl_run_control.sql)

### Validation

- [Data Quality Checks — data_quality_checks.sql](../validation/data_quality_checks.sql)
- [ETL Reconciliation — reconciliation.sql](../validation/reconciliation.sql)

### Sample Data

- [Sample Data Documentation](../sample-data/README.md)
- [Oracle Source Data — customer.csv](../sample-data/source/customer.csv)
- [Expected Valid Output — stg_customer.csv](../sample-data/expected/stg_customer.csv)
- [Expected Reject Output — stg_customer_rej.csv](../sample-data/expected/stg_customer_rej.csv)

### IDMC

- [IDMC Taskflow Design](taskflow-design.md)

### Project Documentation

- [Main Project README](../README.md)
- [IDMC Customer Mapping Diagram](../images/idmc-customer-mapping.png)

---

## 15. Production Design Note

This repository is a simplified portfolio implementation of an enterprise ETL pattern.

In a production environment, runtime values such as:

```text
RUN_ID
LAST_RUN_TIMESTAMP
```

would normally be supplied or derived dynamically by the orchestration process rather than hard-coded into the mapping.

The taskflow would control the execution sequence, record run status, execute reconciliation, handle failures, and advance the successful-run timestamp only after successful processing.

The sample values in this repository are used to make the complete ETL flow easy to follow and test.

---

## 16. Final Mapping Flow

```text
Oracle CUSTOMER
4 records
      |
      | LAST_UPDATED > 2026-08-15
      |
      +---- 1001 John
      |     Filtered Out
      |
      v
3 Incremental Records
      |
      v
IDMC Source
      |
      v
Expression
Standardize Data
Add RUN_ID
Add SOURCE_SYSTEM
      |
      v
Data Validation
      |
      v
Router
     / \
    /   \
   v     v
VALID   REJECT
  2       1
  |       |
  v       v
STG_CUSTOMER     STG_CUSTOMER_REJ
  |                    |
  +----------+---------+
             |
             v
       Reconciliation

SOURCE     = 3
LOADED     = 2
REJECTED   = 1
DIFFERENCE = 0

STATUS = PASS
```

---

## About the Example

All customer records, timestamps, `RUN_ID` values, table names, and processing examples in this mapping design are synthetic and created specifically for portfolio demonstration purposes.

No proprietary production code, credentials, company data, or customer information is included.
