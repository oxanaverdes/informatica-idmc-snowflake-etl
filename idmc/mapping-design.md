# Informatica IDMC Mapping Design

## Mapping

**Name:** `m_Load_Customer_To_Snowflake`

## Purpose

Extract new and updated customer records from Oracle and load them into the Snowflake staging layer for downstream dimensional processing.

## Data Flow

<img width="1536" height="1024" alt="image" src="https://github.com/user-attachments/assets/d1ff8d12-7267-475e-8449-af9404b4c9fa" />

## Mapping Walkthrough with Sample Data

Instead of only describing each transformation, the example below shows how customer records change as they move through the IDMC mapping.

### 1. Oracle Source

Assume the previous successful ETL run was:

`LAST_RUN_TIMESTAMP = 2026-08-15 00:00:00`

Oracle CUSTOMER contains:

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

Customer **1001 is not extracted** because the record was last updated before the previous successful run.

The mapping therefore receives:

| CUSTOMER_ID | FIRST_NAME | STATE | STATUS | LAST_UPDATED |
|---:|---|---|---|---|
| 1002 | ` Maria ` | in | active | 2026-08-18 |
| 1003 | David | oh | inactive | 2026-08-20 |
| NULL | Robert | in | active | 2026-08-21 |

**4 source records → 3 incremental records**

---

### 2. Expression Transformation

IDMC standardizes the incoming values.

Example transformation rules:

```text
FIRST_NAME = TRIM(FIRST_NAME)
STATE      = UPPER(STATE)
STATUS     = UPPER(STATUS)
SOURCE_SYSTEM = 'ORACLE'
```

Before:

| CUSTOMER_ID | FIRST_NAME | STATE | STATUS |
|---:|---|---|---|
| 1002 | ` Maria ` | in | active |
| 1003 | David | oh | inactive |
| NULL | Robert | in | active |

After:

| CUSTOMER_ID | FIRST_NAME | STATE | STATUS | SOURCE_SYSTEM |
|---:|---|---|---|---|
| 1002 | Maria | **IN** | **ACTIVE** | ORACLE |
| 1003 | David | **OH** | **INACTIVE** | ORACLE |
| NULL | Robert | **IN** | **ACTIVE** | ORACLE |

**Changes:** spaces removed, state/status standardized, ETL metadata added.

---

### 3. Router Transformation

The Router separates valid and invalid records.

#### VALID_RECORDS

Condition:

```text
NOT ISNULL(CUSTOMER_ID)
```

Records:

| CUSTOMER_ID | FIRST_NAME | STATE | STATUS |
|---:|---|---|---|
| 1002 | Maria | IN | ACTIVE |
| 1003 | David | OH | INACTIVE |

These records continue to Snowflake.

#### REJECT_RECORDS

Condition:

```text
ISNULL(CUSTOMER_ID)
```

Record:

| CUSTOMER_ID | FIRST_NAME | STATE | STATUS | REJECT_REASON |
|---:|---|---|---|---|
| NULL | Robert | IN | ACTIVE | Missing CUSTOMER_ID |

This record does **not** continue to the normal target. It is captured for investigation and possible reprocessing.

**3 records received → 2 valid + 1 rejected**

---

### 4. Snowflake Target — STG_CUSTOMER

The two valid records are loaded into Snowflake:

| CUSTOMER_ID | FIRST_NAME | STATE | STATUS | SOURCE_SYSTEM | LOAD_TIMESTAMP |
|---:|---|---|---|---|---|
| 1002 | Maria | IN | ACTIVE | ORACLE | 2026-08-21 02:05 |
| 1003 | David | OH | INACTIVE | ORACLE | 2026-08-21 02:05 |

The final mapping result is:

```text
Oracle CUSTOMER
      │
      │ 4 records
      ▼
Incremental Extract
      │
      │ 3 changed records
      ▼
Expression
      │
      │ values standardized
      ▼
Router
     / \
    /   \
   ▼     ▼
VALID   REJECT
  2       1
  │       │
  ▼       ▼
STG_    Error /
CUSTOMER Reject
```

### Result

| ETL Step | Record Count |
|---|---:|
| Oracle source | 4 |
| Incrementally extracted | 3 |
| Valid | 2 |
| Rejected | 1 |
| Loaded to STG_CUSTOMER | 2 |

This makes the processing result easy to reconcile:

**3 extracted = 2 loaded + 1 rejected**
