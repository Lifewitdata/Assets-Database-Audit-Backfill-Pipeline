# Assets-Database-Audit-Backfill-Pipeline


A MySQL-based data management system that models private equity fund data, audits coverage gaps, automates bulk backfills, and generates a weekly coverage dashboard — built to reflect real workflows used in private markets data teams.

---

## 📌 Project Overview

Private markets data is messy. Valuations go missing. Deals have incomplete fields. Funds exist in the system with no coverage at all. This project simulates the full data quality lifecycle a data analyst runs at a firm like Preqin or BlackRock:

- Model fund, deal, and valuation data in a relational database
- Write audit queries to find every gap and inconsistency
- Use window functions to rank and compare fund performance
- Automate bulk backfills with a stored procedure and full audit trail
- Produce a coverage dashboard report for team review

---

## 🗂️ Project Structure

```
preqin_db/
├── 01_setup.sql                ← database schema + sample data
├── 02_audit_queries.sql        ← find missing values, stale records, coverage gaps
├── 03_window_functions.sql     ← rank and compare fund performance over time
├── 04_stored_procedure.sql     ← automated bulk backfill with audit logging
└── 05_coverage_report.sql      ← final dashboard: health scorecard + summaries
```

---

## 🏗️ Database Schema

Three tables that mirror how alternative asset data is structured in practice:

```
funds
├── fund_id          (PK)
├── fund_name
├── asset_class      ← Private Equity, Venture Capital, Infrastructure, Growth Equity
├── geography        ← North America, Europe, Asia Pacific, Global
├── fund_size_usd_m  ← can be NULL (missing data we flag in audit)
├── vintage_year
└── status           ← Active / Closed

deals
├── deal_id          (PK)
├── fund_id          (FK → funds)
├── company_name
├── deal_type        ← Buyout, Growth, Venture
├── deal_size_usd_m  ← can be NULL
├── deal_date        ← can be NULL
├── sector
└── country

valuations
├── valuation_id     (PK)
├── fund_id          (FK → funds)
├── quarter          ← e.g. Q1-2024, Q2-2024
├── nav_usd_m        ← Net Asset Value in USD millions, can be NULL
└── reported_date

backfill_log         ← created by the stored procedure
├── log_id           (PK)
├── fund_id
├── fund_name
├── quarter
├── old_nav          ← what was there before
├── new_nav          ← what we filled in
├── fill_method      ← how the value was calculated
├── filled_by        ← analyst name passed into the procedure
└── filled_at        ← timestamp of the change
```

---

## 📋 What Each File Does

### `01_setup.sql` — Schema & Sample Data
Creates the database and all four tables. Inserts 10 funds, 12 deals, and 15 valuations with intentional gaps to simulate real-world incomplete data.

```sql
CREATE DATABASE IF NOT EXISTS preqin_db;
USE preqin_db;
-- creates funds, deals, valuations tables
-- inserts sample data with deliberate NULLs for audit practice
```

---

### `02_audit_queries.sql` — Coverage Gap Detection
Six queries that find every data quality problem:

| Query | What it finds |
|---|---|
| Query 1 | Valuations with NULL nav or missing report date |
| Query 2 | Funds with zero valuations (LEFT JOIN) |
| Query 3 | Active funds missing a specific quarter |
| Query 4 | Deals with missing size, date, or sector (CASE WHEN) |
| Query 5 | Coverage summary by asset class (CTE) |
| Query 6 | Stale records not updated in 90+ days (DATEDIFF + HAVING) |

---

### `03_window_functions.sql` — Performance Analysis
Four window function queries for time-series and ranking analysis:

| Query | Function used | Purpose |
|---|---|---|
| Query 1 | `ROW_NUMBER()` | Number each fund's quarters chronologically |
| Query 2 | `RANK()` | Rank funds by NAV within asset class |
| Query 3 | `LAG()` | Quarter-over-quarter NAV change and % growth |
| Query 4 | `SUM() OVER()` | Running AUM total and % share per asset class |

---

### `04_stored_procedure.sql` — Bulk Backfill Automation
A stored procedure `run_backfill()` that loops through every missing NAV for a given quarter and fills it using a 4-strategy decision tree:

```
Missing NAV found
      │
      ├── previous AND next quarter exist?  →  average of both
      ├── only previous quarter exists?     →  carry forward
      ├── only next quarter exists?         →  carry back
      └── no adjacent data at all?          →  asset class average
```

Every fill is logged to `backfill_log` with the analyst name, timestamp, old value, new value, and method used.

```sql
-- how to run it
SET @rows_filled = 0;
CALL run_backfill('Q2-2024', 'analyst_john', @rows_filled);
SELECT @rows_filled AS rows_filled;
```

---

### `05_coverage_report.sql` — Coverage Dashboard
Five report queries that make up the weekly team dashboard:

| Report | What it shows |
|---|---|
| Report 1 | Overall database health — total records + completeness % per table |
| Report 2 | AUM and deal volume breakdown by asset class and geography |
| Report 3 | Fund performance league table with QoQ NAV change and growth flag |
| Report 4 | Backfill activity log — records filled, methods used, analyst breakdown |
| Report 5 | Per-fund health scorecard — fund size, deals, Q2 valuation — scored out of 3 |

---

## 🚀 How to Run

**Requirements:** MySQL 8.0+ and MySQL Workbench (or any MySQL client)

```bash
# 1. Open MySQL Workbench and connect to localhost
# 2. Run each file in order:

01_setup.sql              ← run first, creates everything
02_audit_queries.sql      ← run queries one by one
03_window_functions.sql   ← run queries one by one
04_stored_procedure.sql   ← run full file, then CALL the procedure
05_coverage_report.sql    ← run reports one by one
```

> **Tip:** In MySQL Workbench, use `Ctrl + Shift + Enter` to run the entire file, or highlight a single query and press `Ctrl + Enter` to run just that one.

---

## 🧠 SQL Concepts Covered

- **JOINs** — INNER JOIN, LEFT JOIN for gap detection
- **CTEs** — WITH clause for readable multi-step logic
- **Window Functions** — ROW_NUMBER, RANK, LAG, SUM OVER with PARTITION BY
- **Stored Procedures** — cursor loops, IF/ELSEIF logic, IN/OUT parameters
- **Audit Logging** — INSERT into log table on every data change
- **CASE WHEN** — inline conditional logic for labelling and scoring
- **DATEDIFF + HAVING** — filtering on aggregated date expressions
- **UNION ALL** — combining results from multiple tables into one report

---

## 📊 Sample Output — Health Scorecard (Report 5)

```
+---------+-----------------------------+------------------+------------------+--------------+---------------------+--------------+
| fund_id | fund_name                   | asset_class      | fund_size_status | deals_status | q2_valuation_status | health_score |
+---------+-----------------------------+------------------+------------------+--------------+---------------------+--------------+
|       8 | GreenSpring Associates Fund | Venture Capital  | Missing          | No deals     | Missing Q2          |            0 |
|       9 | Warburg Pincus Global Growth| Growth Equity    | OK               | No deals     | Missing Q2          |            1 |
|       1 | Blackstone Capital Partners | Private Equity   | OK               | OK           | OK                  |            3 |
|       2 | Apollo Investment Fund XI   | Private Equity   | OK               | OK           | OK                  |            3 |
|       3 | Sequoia Capital Global Fund | Venture Capital  | OK               | OK           | OK                  |            3 |
+---------+-----------------------------+------------------+------------------+--------------+---------------------+--------------+
```

Funds with `health_score = 0` are flagged for immediate attention. Score of 3 = fully clean.

---

## 💼 Why This Project

This project was built to demonstrate the core skills required in a private markets data role:

- Writing complex SQL to audit and improve data quality
- Automating repetitive data tasks with stored procedures
- Maintaining clear documentation and audit trails for every change
- Producing summary reports that non-technical stakeholders can read

The dataset and workflows mirror what data teams at firms like Preqin, PitchBook, and Bloomberg handle daily across private equity, venture capital, and infrastructure asset classes.

---

## 📁 Tech Stack

| Tool | Purpose |
|---|---|
| MySQL 8.0 | Database engine |
| MySQL Workbench | Query editor and schema viewer |
| SQL | All data modelling, analysis, and automation |

---

## 👤 Author
Isfaque Ansari 
Built as a portfolio project demonstrating SQL skills for private markets data roles.  
Feel free to fork, adapt the schema, or extend the stored procedure with additional fill strategies.
