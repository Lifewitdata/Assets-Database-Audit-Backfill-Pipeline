# Property Research Database — Coverage, Evidence & Audit Trails

**Start with the executed Python analysis:** [Open the Jupyter notebook](notebooks/01_property_data_quality_and_recovery.ipynb). It includes visible Python code, result tables, charts and written findings. Streamlit is an optional dashboard, not a replacement for the analysis.

To run the notebook, install the project's dependencies below, then `python -m pip install -r requirements-notebooks.txt`. Open it in Jupyter or VS Code and run all cells from a fresh kernel. For automated execution, run `python scripts/verify_notebooks.py`. GitHub Actions executes every cell as a separate check.

A Python/SQL project demonstrating the database maintenance behind real estate market research: identify missing fields, recover them from traceable source evidence, preserve unresolved exceptions and prepare a reviewer brief.

This complements a comparable-sales analysis project by focusing on **research database reliability and controlled updates**, not valuation modelling.

## Verified demonstration

| Measure | Result |
|---|---:|
| Official NYC DOF Brooklyn C1/C2/C3 sales records | 2,373 |
| Audited cells across four fields | 9,492 |
| Deliberately introduced local gaps | 80 |
| Exact source-backed recoveries | 80 |
| Unsupported proposals rejected | 1 |
| Records still triggering research review | 1,216 |

**The 80 gaps are simulated import failures.** The source dataset is real; these recovery results are not a claimed business achievement. Field completeness rises from 99.16% to 100% in the demonstration, but complete records can still contain zero consideration, invalid area or possible package-sale signals. Nothing here concludes a property's market value.

[Read the reviewer brief](reports/reviewer_report.md) · [Coverage report](reports/coverage_by_neighborhood.csv) · [Audit trail](reports/audit_log.csv) · [Run summary](reports/summary.json)

## Run

Python 3.10+; SQLite is included in Python, so no database server or credentials are needed.

```bash
python -m pip install -r requirements.txt
python research.py
streamlit run app.py
python -m pytest -q
```

The pipeline creates `outputs/demo/research.sqlite`, CSV review files and a Markdown brief. It refuses to replace an existing database to preserve audit history. For a fresh run, use `python research.py --output outputs/second_run`. To show it in the dashboard, set `PROPERTY_AUDIT_OUTPUT=outputs/second_run` in your environment.

## Workflow

1. Verify the committed official extract's checksum and row count; load sources, records and field-level evidence into relational tables.
2. Introduce 80 explicitly simulated gaps in the working records; original evidence remains unchanged.
3. Evaluate proposed recoveries against exact record, field, source ID, source row and source value.
4. Apply only null-field recoveries within an atomic transaction; log every applied update. Reject mismatches and preserve existing values.
5. Export neighborhood/class coverage, exception records, proposal outcomes and a reviewer report. Browse four dashboard tabs.

No averages, carry-forward prices, inferred NAVs or invented valuation figures enter the property workflow. `DEMO_REVIEWER` is a test identity, not a licensed appraiser's signoff. The dashboard is read-only; the Python API performs controlled updates.

## Skills demonstrated

Python/pandas; relational SQL joins, CTEs and aggregation; foreign keys and unique constraints; transaction safety; source reconciliation; completeness and business-rule checks; audit logging; Streamlit reporting; GitHub Actions and regression tests.

The active implementation uses **SQLite**. The original MySQL private-fund exercise is preserved in [legacy/](legacy/) and is not invoked by the property pipeline. Its estimated NAV backfill should not be presented as verified appraisal evidence.

## Sources and scope

Official NYC Department of Finance 2024/2025 Brooklyn sales, classes C1/C2/C3. The committed extract contains all scoped records, including questionable transactions, not only cleaned comparables. [Source registry](data/sources.json) records original URLs, workbook hashes and publication notes. The identical extract also supports the companion [comparable-sales project](https://github.com/Lifewitdata/Real-Estate-Motors-Marketplace-Analytics).

[Methodology and limitations](docs/methodology.md) · [Data dictionary](docs/data_dictionary.md) · [Source documentation](docs/sources.md)

This is a single-provider portfolio demonstration. It does not claim access to Newmark systems, independent deed verification, property inspections, a production authorization system or certified appraiser review.
