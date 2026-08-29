# Informatica IDMC + Snowflake ETL Pipeline

End-to-end ETL portfolio project demonstrating incremental data integration from **Oracle → Informatica IDMC → Snowflake**, including transformation, data validation, reject handling, SCD Type 2 processing, and source-to-target reconciliation.

## Architecture

```text
Oracle CUSTOMER
      |
      | Incremental Extract
      | LAST_UPDATED > LAST_RUN_TIMESTAMP
      v
Informatica IDMC
      |
      | Source
      | Expression
      | Validation
      | Router
      |
      +---------------------+
      |                     |
      v                     v
VALID_RECORDS         REJECT_RECORDS
      |                     |
      v                     v
STG_CUSTOMER       STG_CUSTOMER_REJ
      |
      v
SCD Type 2 Processing
      |
      v
DIM_CUSTOMER
      |
      v
Reconciliation
      |
      v
PASS / FAIL
```

## Technologies

| Area | Technology |
|---|---|
| Data Integration | Informatica IDMC / IICS |
| Source Database | Oracle |
| Cloud Data Warehouse | Snowflake |
| Development | SQL / PL/SQL |
| ETL Pattern | Incremental Load |
| Data Warehousing | SCD Type 2 |
| Data Quality | Validation & Reject Handling |
| Production Support | Reconciliation, Monitoring & RCA |

## Sample ETL Run

Previous successful run:

`LAST_RUN_TIMESTAMP = 2026-08-15 00:00:00`

Sample Oracle records:

| CUSTOMER_ID | FIRST_NAME | STATE | STATUS | LAST_UPDATED |
|---:|---|---|---|---|
| 1001 | John | il | active | 2026-08-10 |
| 1002 | Maria | in | active | 2026-08-18 |
| 1003 | David | oh | inactive | 2026-08-20 |
| NULL | Robert | in | active | 2026-08-21 |

Incremental condition:

```sql
WHERE LAST_UPDATED > :LAST_RUN_TIMESTAMP
```

Customer `1001` is not extracted because the record was updated before the previous successful run.

The remaining **3 records** enter the IDMC mapping.

## IDMC Transformation Example

The Expression transformation standardizes incoming values.

```text
Maria:   " Maria " → "Maria"
STATE:   "in"      → "IN"
STATUS:  "active"  → "ACTIVE"
```

The Router then separates valid and rejected records:

| Customer | Result | Destination |
|---|---|---|
| 1002 Maria | Valid | STG_CUSTOMER |
| 1003 David | Valid | STG_CUSTOMER |
| NULL Robert | Rejected | STG_CUSTOMER_REJ |

Robert is rejected because `CUSTOMER_ID` is missing.

## Reconciliation

Every extracted record must be accounted for.

```text
RUN_ID      = 20260829_020000

SOURCE      = 3
LOADED      = 2
REJECTED    = 1
DIFFERENCE  = 0

STATUS      = PASS
```

Validation rule:

```text
SOURCE = LOADED + REJECTED

3 = 2 + 1
```

If the difference is not zero, the ETL run requires investigation.

## SCD Type 2

Customer history is preserved in `DIM_CUSTOMER`.

For example, if a customer moves from Illinois to Indiana:

```text
Before

CUSTOMER_ID   STATE   IS_CURRENT
1002          IL      TRUE


After Change

CUSTOMER_ID   STATE   IS_CURRENT
1002          IL      FALSE
1002          IN      TRUE
```

The previous version is retained instead of being overwritten.

## IDMC Design

Detailed IDMC mapping design:

➡️ [IDMC Mapping Design](idmc/mapping-design.md)

The mapping demonstrates:

- Incremental Oracle extraction
- Expression transformations
- Data validation
- Router logic
- Valid/reject processing
- Snowflake staging load

Detailed orchestration:

➡️ [IDMC Taskflow Design](idmc/taskflow-design.md)

The taskflow demonstrates:

- Runtime parameters
- Incremental timestamp handling
- Mapping execution
- SCD Type 2 processing
- Reconciliation
- Success/failure handling
- Restart/reprocessing logic

## Repository Structure

```text
informatica-idmc-snowflake-etl/
│
├── oracle/
│   ├── create_customer.sql
│   └── incremental_extract.sql
│
├── idmc/
│   ├── mapping-design.md
│   └── taskflow-design.md
│
├── snowflake/
│   ├── create_stage_tables.sql
│   ├── create_reject_table.sql
│   ├── create_dimension.sql
│   └── merge_customer.sql
│
├── validation/
│   └── reconciliation.sql
│
├── sample-data/
│   └── source/
│       └── customer.csv
│
└── README.md
```

## Key ETL Concepts Demonstrated

- Oracle source extraction
- Incremental loading using timestamps
- Informatica IDMC mapping design
- Expression transformations
- Router-based validation
- Reject/error handling
- Snowflake staging
- SCD Type 2 dimensional processing
- Source-to-target reconciliation
- ETL restart and recovery concepts
- Production monitoring and root-cause analysis

## About This Project

This project is a simplified portfolio implementation based on common enterprise ETL patterns.

All data, table names, customer records, and examples are synthetic and created specifically for demonstration purposes. No proprietary production code or company data is included.
