# Methodology, controls and limits

## Identity and evidence

One record per source workbook row; `record_id` derives from workbook ID and row number. The same parcel may legitimately appear in multiple transactions. `bbl` is a parcel identifier, not a unique sale key. Evidence retains every original audited field's source value and row, separately from the working record.

Snapshot SHA-256 verification occurs before loading. Foreign keys prevent orphan records/proposals and unique keys prevent duplicate source rows or duplicated field evidence. SQL values are parameterized; dynamic column names are restricted to a fixed four-field allowlist.

## Demonstration design

Choose 80 records in deterministic record-ID order with positive price, adequate area and at least four residential units. Remove one field per record, cycling through address, consideration, gross area and unit count. These gaps exist only in the local database, not in the original source extract. Create 80 exact-source recovery proposals and one deliberately unsupported proposal. Every recovery uses the same provider, not independent confirmation.

## Update safeguards

Acquire a write lock, validate pending status and source identity/value, require a missing destination field and positive numeric recovery values, then update data, append the evidence/reviewer audit and change proposal status in one transaction. Any failure rolls back all writes. Reapplying a completed proposal is idempotent. Existing values are never overwritten by this recovery API; conflicts are rejected for investigation. The recorded reviewer is supplied to the API and is not authenticated or professionally certified.

The demo applies its known fixtures automatically under DEMO_REVIEWER. An operational deployment would require authenticated reviewer roles, approval workflow, source access controls, backups, immutable audit retention and a separate conflict-resolution process. Local SQLite files can be altered by their owner; audit logs here are transactional, not tamper-proof.

## Quality versus suitability

Completeness counts non-null values in four fields, not economic correctness. Separate flags identify missing fields, nonpositive consideration, nonpositive area and repeated same-date consideration across distinct parcels. Flags overlap and their counts must not be summed as unique records. Package-sale detection is only a signal within the scoped extract; unrelated sales can share an amount/date and packages outside this scope may be missed.

No appraisal eligibility score is produced. Additional checks for legal rights, condition, financing, deed terms, location and independently verified area remain outstanding. No income/cost approach or estimated market value is produced. Dates are historical sale dates; later publication of annual files rules out a point-in-time information claim.

## Reviewer process

Use neighborhood coverage to prioritize incomplete areas. Inspect source ID/row before resolving an exception. Obtain authorized independent evidence for price/area conflicts and package allocation. Record unresolved issues for the supervising appraiser. The generated brief separates software results from professional appraisal decisions.
