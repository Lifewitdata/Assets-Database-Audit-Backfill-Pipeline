# Property Research Database — Reviewer Brief

**Purpose:** demonstrate reliable market-data collection, database maintenance and exception reporting for supervised appraisal research.

**Data:** 2,373 official Brooklyn C1/C2/C3 sale records from NYC DOF annual 2024/2025 workbooks. Source workbook hashes and row references are retained. These are recorded transactions, not verified appraisals.

## Findings
- Controlled simulation removed 80 otherwise available field values from a local working copy. This is a demonstration of import gaps, not a claim that the provider lost data.
- 80 missing values were restored by exact source record/field matches, with reviewer label, evidence row and audit timestamp. No estimated valuation was inserted.
- Field completeness changed from 99.16% to 100.0% across 9,492 audited cells. This is a simulation result, not a measured workplace improvement.
- 1 unsupported proposals were rejected. 1216 records still trigger review rules; complete fields do not establish valid market evidence.

## Recommended actions
1. Investigate zero/nonpositive consideration, missing area and possible package-sale records before using them in price comparisons.
2. Verify ambiguous records against deeds and authorized independent sources; repeated price/date across parcels is a signal, not proof of a package transaction.
3. Retain unresolved gaps and existing-value conflicts in the exception queue. Do not replace missing prices with averages or carry-forward estimates.
4. Have a supervising appraiser review transaction terms and property evidence before making any valuation conclusion.

## Limits
The workflow uses one external provider, no internal Newmark database or proprietary feed. DEMO_REVIEWER is a software test identity, not professional approval. Annual sources were published after their sale periods; no contemporaneous valuation claim is made. Missingness checks and selected business flags are not comprehensive appraisal due diligence. The SQLite implementation is locally executable; the original MySQL fund example is historical material in legacy/.
