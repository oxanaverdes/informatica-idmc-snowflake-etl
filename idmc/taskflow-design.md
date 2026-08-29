# Informatica IDMC Taskflow Design

## Taskflow

**Name:** `tf_Customer_Oracle_To_Snowflake`

## Purpose

The taskflow controls the complete customer ETL process from Oracle to Snowflake.

It runs the IDMC mapping, checks the result, processes the customer dimension, performs reconciliation, and updates the incremental timestamp only after a successful run.

---

## Sample ETL Run

For this example:

| Parameter | Value |
|---|---|
| RUN_ID | `20260829_020000` |
| LAST_RUN_TIMESTAMP | `2026-08-15 00:00:00` |
| Source Records | 3 |
| Valid Records | 2 |
| Rejected Records | 1 |

The three records selected from Oracle are:

| CUSTOMER_ID | FIRST_NAME | LAST_UPDATED | Result |
|---:|---|---|---|
| 1002 | Maria | 2026-08-18 | Valid |
| 1003 | David | 2026-08-20 | Valid |
| NULL | Robert | 2026-08-21 | Rejected |

---

## Taskflow Execution

### Step 1 — Start

The scheduled ETL process begins.

```text
RUN_ID = 20260829_020000
```

---

### Step 2 — Read Previous Successful Run

The taskflow obtains:

```text
LAST_RUN_TIMESTAMP = 2026-08-15 00:00:00
```

This value controls the incremental Oracle extraction.

Only records with:

```sql
LAST_UPDATED > :LAST_RUN_TIMESTAMP
```

are processed.

---

### Step 3 — Run IDMC Mapping

The taskflow executes:

`m_Load_Customer_To_Snowflake`

The mapping extracts 3 records.

```text
                    IDMC MAPPING
                      3 records
                          |
                   +------+------+
                   |             |
                   v             v
                 VALID         REJECT
                   2              1
                   |              |
                   v              v
           STG_CUSTOMER    STG_CUSTOMER_REJ
```

Result:

| Target | Count |
|---|---:|
| STG_CUSTOMER | 2 |
| STG_CUSTOMER_REJ | 1 |

---

### Step 4 — Process DIM_CUSTOMER

Valid staging records are processed into:

`DIM_CUSTOMER`

The Snowflake processing applies SCD Type 2 logic.

For a changed customer:

```text
Existing Current Record
        |
        v
Set IS_CURRENT = FALSE
Set EFFECTIVE_TO
        |
        v
Insert New Version
        |
        v
IS_CURRENT = TRUE
```

This preserves customer history instead of overwriting the previous record.

---

### Step 5 — Reconciliation

The taskflow validates that every extracted record is accounted for.

```text
SOURCE      = 3
LOADED      = 2
REJECTED    = 1

DIFFERENCE
= SOURCE - (LOADED + REJECTED)

= 3 - (2 + 1)

= 0
```

Result:

```text
STATUS = PASS
```

---

## Successful Run

When reconciliation passes:

```text
SOURCE = LOADED + REJECTED

3 = 2 + 1
```

The taskflow can update the successful-run timestamp.

```text
Previous LAST_RUN_TIMESTAMP
2026-08-15 00:00:00

            ↓

New LAST_RUN_TIMESTAMP
2026-08-29 02:00:00
```

The next ETL execution will process records updated after the new timestamp.

---

## Failure Example

Suppose the source extracted 3 records, but only 1 valid and 1 rejected record can be accounted for:

```text
SOURCE      = 3
LOADED      = 1
REJECTED    = 1

DIFFERENCE
= 3 - (1 + 1)

= 1
```

Result:

```text
STATUS = FAIL
```

The taskflow should **not update `LAST_RUN_TIMESTAMP`**.

```text
              RECONCILIATION
                     |
             +-------+-------+
             |               |
             v               v
           PASS             FAIL
             |               |
             v               v
 Update Successful      Keep Previous
 Run Timestamp          Run Timestamp
             |               |
             v               v
            END       Investigate / Reprocess
```

Keeping the previous successful timestamp helps prevent unprocessed records from being skipped after a failed ETL run.

---

## End-to-End Taskflow

```text
                    START
                      |
                      v
             Read LAST_RUN_TIMESTAMP
                      |
                      v
               Run IDMC Mapping
                      |
                      v
                 3 Records
                      |
               +------+------+
               |             |
               v             v
            2 VALID       1 REJECT
               |             |
               v             v
        STG_CUSTOMER   STG_CUSTOMER_REJ
               |
               v
        Process DIM_CUSTOMER
               |
               v
           Reconciliation
               |
          +----+----+
          |         |
          v         v
        PASS       FAIL
          |         |
          v         v
 Update Last     Keep Previous
 Run Timestamp   Timestamp
          |         |
          v         v
         END    Investigate /
                Reprocess
```

## Production Monitoring

For each execution, the following information should be available for monitoring and troubleshooting:

| Metric | Example |
|---|---|
| RUN_ID | 20260829_020000 |
| Source Count | 3 |
| Loaded Count | 2 |
| Rejected Count | 1 |
| Difference | 0 |
| Status | PASS |
| Previous Run Timestamp | 2026-08-15 00:00:00 |
| Current Run Timestamp | 2026-08-29 02:00:00 |

This information helps with ETL monitoring, reconciliation, root-cause analysis, and restart/reprocessing decisions.
