# Informatica IDMC Mapping Design

## Mapping

**Name:** `m_Load_Customer_To_Snowflake`

## Purpose

Extract new and updated customer records from Oracle and load them into Snowflake staging.

The mapping also standardizes incoming data, validates required fields, routes rejected records, and assigns a common `RUN_ID` so all records can be traced back to one ETL execution.

---

## Data Flow

<img width="1536" height="1024" alt="image" src="https://github.com/user-attachments/assets/d1ff8d12-7267-475e-8449-af9404b4c9fa" />

---

# Mapping Walkthrough with Sample Data

Instead of only describing each transformation, the example below shows how customer records change as they move through the IDMC mapping.

For this sample run:

```text
RUN_ID = 20260829_020000

LAST_RUN_TIMESTAMP = 2026-08-15 00:00:00
```

The same `RUN_ID` is carried through the mapping and stored with both valid and rejected records.

---

## 1. Oracle Source

Oracle `CUSTOMER` contains:

| CUSTOMER_ID | FIRST_NAME | LAST_NAME | EMAIL | STATE | STATUS | LAST_UPDATED |
|---:|---|---|---|---|---|---|
| 1001 | ` John ` | Smith | john.smith@example.com | il | active | 2026-08-10 |
| 1002 | ` Maria ` | Garcia | maria.garcia@example.com | in | active | 2026-08-18 |
| 1003 | David | Brown | david.brown@example.com | oh | inactive | 2026-08-20 |
| NULL | Robert | Davis | robert.davis@example.com | in | active | 2026-08-21 |

The incremental source condition is:

```sql
WHERE LAST_UPDATED > :LAST_RUN_TIMESTAMP
```

`:LAST_RUN_TIMESTAMP` represents the previous successful ETL execution timestamp supplied at runtime.

For this sample:

```text
LAST_RUN_TIMESTAMP = 2026-08-15 00:00:00
```

Therefore:

| Customer | LAST_UPDATED | Result |
|---|---|---|
| 1001 John | Aug 10 | Filtered out |
| 1002 Maria | Aug 18 | Extracted |
| 1003 David | Aug 20 | Extracted |
| NULL Robert | Aug 21 | Extracted |

Customer **1001 is not extracted** because the record was last updated before the previous successful run.

The mapping therefore receives:

| CUSTOMER_ID | FIRST_NAME | STATE | STATUS | LAST_UPDATED |
|---:|---|---|---|---|
| 1002 | ` Maria ` | in | active | 2026-08-18 |
| 1003 | David | oh | inactive | 2026-08-20 |
| NULL | Robert | in | active | 2026-08-21 |

**4 source records → 3 incremental records**

---

## 2. Expression Transformation

IDMC standardizes incoming values and adds ETL metadata.

Example transformation logic:

```text
FIRST_NAME    = TRIM(FIRST_NAME)

STATE         = UPPER(STATE)

STATUS        = UPPER(STATUS)

SOURCE_SYSTEM = 'ORACLE'

RUN_ID        = Taskflow runtime RUN_ID
```

For this run:

```text
RUN_ID = 20260829_020000
```

### Before Expression

| CUSTOMER_ID | FIRST_NAME | STATE | STATUS |
|---:|---|---|---|
| 1002 | ` Maria ` | in | active |
| 1003 | David | oh | inactive |
| NULL | Robert | in | active |

### After Expression

| CUSTOMER_ID | FIRST_NAME | STATE | STATUS | SOURCE_SYSTEM | RUN_ID |
|---:|---|---|---|---|---|
| 1002 | Maria | **IN** | **ACTIVE** | ORACLE | 20260829_020000 |
| 1003 | David | **OH** | **INACTIVE** | ORACLE | 20260829_020000 |
| NULL | Robert | **IN** | **ACTIVE** | ORACLE | 20260829_020000 |

### Changes Applied

- Extra spaces removed from customer names
- State standardized to uppercase
- Status standardized to uppercase
- `SOURCE_SYSTEM` populated
- `RUN_ID` populated from the taskflow

The `RUN_ID` allows every record to be associated with the ETL execution that processed it.

---

## 3. Router Transformation

The Router separates valid and invalid records.

---

### VALID_RECORDS

Condition:

```text
NOT ISNULL(CUSTOMER_ID)
```

Records:

| CUSTOMER_ID | FIRST_NAME | STATE | STATUS | RUN_ID |
|---:|---|---|---|---|
| 1002 | Maria | IN | ACTIVE | 20260829_020000 |
| 1003 | David | OH | INACTIVE | 20260829_020000 |

These records continue to the normal Snowflake staging target:

`STG_CUSTOMER`

Both records preserve:

```text
RUN_ID = 20260829_020000
```

---

### REJECT_RECORDS

Condition:

```text
ISNULL(CUSTOMER_ID)
```

Rejected record:

| CUSTOMER_ID | FIRST_NAME | STATE | STATUS | REJECT_REASON | RUN_ID |
|---:|---|---|---|---|---|
| NULL | Robert | IN | ACTIVE | Missing CUSTOMER_ID | 20260829_020000 |

This record does **not** continue to the normal staging target.

It is routed to:

`STG_CUSTOMER_REJ`

for investigation, correction, and possible reprocessing.

The rejected record preserves the same:

```text
RUN_ID = 20260829_020000
```

This makes it possible to reconcile valid and rejected records from the same ETL execution.

---

## 4. Snowflake Target — STG_CUSTOMER

The two valid records are loaded into Snowflake staging.

Example target result:

| CUSTOMER_ID | FIRST_NAME | STATE | STATUS | SOURCE_SYSTEM | RUN_ID | LOAD_TIMESTAMP |
|---:|---|---|---|---|---|---|
| 1002 | Maria | IN | ACTIVE | ORACLE | 20260829_020000 | 2026-08-29 02:05 |
| 1003 | David | OH | INACTIVE | ORACLE | 20260829_020000 | 2026-08-29 02:05 |

The staging table contains the transformed customer records plus ETL metadata.

---

## 5. Snowflake Reject Target — STG_CUSTOMER_REJ

The rejected record is stored separately:

| CUSTOMER_ID | FIRST_NAME | STATE | STATUS | REJECT_REASON | SOURCE_SYSTEM | RUN_ID |
|---:|---|---|---|---|---|---|
| NULL | Robert | IN | ACTIVE | Missing CUSTOMER_ID | ORACLE | 20260829_020000 |

The reject table preserves the source data so the record can be investigated and reprocessed.

---

# End-to-End Mapping Result

```text
Oracle CUSTOMER
      │
      │ 4 source records
      ▼
Incremental Extract
      │
      │ LAST_UPDATED > LAST_RUN_TIMESTAMP
      │
      │ 3 changed records
      ▼
Expression
      │
      │ Standardize data
      │ Add SOURCE_SYSTEM
      │ Add RUN_ID
      ▼
Router
     / \
    /   \
   ▼     ▼
VALID   REJECT
  2       1
  │       │
  ▼       ▼
STG_     STG_
CUSTOMER CUSTOMER_REJ
  │       │
  └───┬───┘
      │
      ▼
RUN_ID = 20260829_020000
      │
      ▼
Reconciliation
```

---

# Mapping Result

| ETL Step | Record Count |
|---|---:|
| Oracle source | 4 |
| Filtered out by incremental logic | 1 |
| Incrementally extracted | 3 |
| Valid | 2 |
| Rejected | 1 |
| Loaded to STG_CUSTOMER | 2 |
| Loaded to STG_CUSTOMER_REJ | 1 |

Reconciliation:

```text
3 extracted = 2 loaded + 1 rejected
```

Therefore:

```text
DIFFERENCE = 0

STATUS = PASS
```

---

# RUN_ID Tracking

For this sample execution:

```text
RUN_ID = 20260829_020000
```

The same `RUN_ID` is stored in:

- `STG_CUSTOMER`
- `STG_CUSTOMER_REJ`
- `ETL_RUN_CONTROL`

This allows reconciliation to evaluate one ETL execution independently from previous or future runs.

Example:

```text
RUN_ID             SOURCE   LOADED   REJECTED   DIFFERENCE   STATUS
-----------------  ------   ------   --------   ----------   ------
20260829_020000       3        2         1           0        PASS
```

---

# Why RUN_ID Matters

Without `RUN_ID`, a query such as:

```sql
SELECT COUNT(*)
FROM STG_CUSTOMER;
```

could count records from many historical ETL executions.

With `RUN_ID`:

```sql
SELECT COUNT(*)
FROM STG_CUSTOMER
WHERE RUN_ID = '20260829_020000';
```

The reconciliation checks only record items belonging to the current ETL run.

This improves:

- ETL monitoring
- Source-to-target reconciliation
- Production troubleshooting
- Root-cause analysis
- Restart and reprocessing
