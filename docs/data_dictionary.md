# Relational data dictionary

| Table | Grain and purpose |
|---|---|
| sources | One annual workbook; URL, workbook SHA-256 and publication notes |
| records | One source row; parcel, neighborhood, address, class, sale date, nominal USD consideration, gross SF and residential units |
| evidence | One record/field; original source value and source identity/row |
| proposals | One proposed field recovery; evidence reference, creator, status and rejection/application reason |
| audit_log | One applied proposal; before/after values, evidence, reviewer label and UTC database timestamp |

`source_row` is the original 1-based Excel row including headings. `record_id` is stable within the committed source snapshot, not an official deed ID. `bbl` is borough-block-lot. C1/C2/C3 denote walk-up apartment classes. Missing fields are SQL NULL. Zero consideration remains zero and receives a business-rule review flag; it is not automatically treated as a missing price.

Exports: `coverage_by_neighborhood.csv` aggregates record counts and four-field presence by neighborhood/class; `record_quality.csv` retains row-level overlapping flags; `proposals.csv` includes rejected updates; `audit_log.csv` contains applied recoveries only. `summary.json` contains simulation totals.
