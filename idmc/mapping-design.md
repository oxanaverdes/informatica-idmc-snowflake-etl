# Informatica IDMC Mapping Design

## Mapping

**Name:** `m_Load_Customer_To_Snowflake`

## Purpose

Extract new and updated customer records from Oracle and load them into the Snowflake staging layer for downstream dimensional processing.

## Data Flow

<img width="1536" height="1024" alt="image" src="https://github.com/user-attachments/assets/d1ff8d12-7267-475e-8449-af9404b4c9fa" />


## Source

**System:** Oracle  
**Table:** CUSTOMER

The source extraction uses `LAST_UPDATED` to support incremental processing.

Only records updated after the previous successful ETL run are selected.

## Transformations

### 1. Source

Reads customer data from Oracle using the incremental extraction logic.

### 2. Expression

Used to standardize incoming values and derive ETL metadata.

Example logic:

- Trim customer names
- Convert STATE to uppercase
- Standardize STATUS
- Populate source-system information

### 3. Router

Records are separated into two groups.

**VALID_RECORDS**
- CUSTOMER_ID is not null
- Required customer information passes validation

**REJECT_RECORDS**
- CUSTOMER_ID is null
- Required validation fails

Valid records continue to Snowflake.

Rejected records are captured for troubleshooting and reprocessing.

## Target

**System:** Snowflake  
**Table:** STG_CUSTOMER

The staging table stores the customer records before dimensional processing.

## Processing Flow

1. Read incremental customer records from Oracle.
2. Apply transformations and validation in IDMC.
3. Route invalid records to reject processing.
4. Load valid records into Snowflake STG_CUSTOMER.
5. Process STG_CUSTOMER into DIM_CUSTOMER.
6. Run source-to-target reconciliation.
7. Record ETL execution results for production monitoring.
