# Sample Customer Data

This sample dataset is designed to demonstrate incremental loading, transformation, validation, and reject handling.

## Incremental Load Scenario

**LAST_RUN_TIMESTAMP = 2026-08-15 00:00:00**

| Customer | LAST_UPDATED | ETL Result |
|---|---|---|
| 1001 John | Aug 10 | ❌ Filtered out |
| 1002 Maria | Aug 18 | ✅ Extracted → VALID |
| 1003 David | Aug 20 | ✅ Extracted → VALID |
| NULL Robert | Aug 21 | ⚠️ Extracted → REJECT |

### Processing Logic

```text
LAST_RUN_TIMESTAMP = Aug 15

1001 John     Aug 10  → FILTERED OUT
1002 Maria    Aug 18  → EXTRACTED → VALID
1003 David    Aug 20  → EXTRACTED → VALID
NULL Robert   Aug 21  → EXTRACTED → REJECT
