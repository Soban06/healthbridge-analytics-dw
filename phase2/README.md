# Phase 2 hospital data warehouse

The PostgreSQL pipeline loads a synthetic hospital snapshot from January through September 2026. It preserves the Phase 1 business entities and fact grains. `build/schema.sql` remains the warehouse table definition.

| Step | What happens |
| --- | --- |
| Source CSVs | `sources/` contains 14 fictional extracts using MRNs, staff IDs, ICD-10 codes and other business identifiers. `generate_sources.py` recreates them from the Phase 1 sample, with controlled cleaning cases. |
| `project_staging` | `run_etl.py` keeps the raw values with file and row numbers, checks values, standardizes fields, and loads typed staging tables. It records duplicates and rejected rows with their reasons. |
| `project_dw` | SQL loads dimensions first, assigns warehouse keys, and closes earlier patient and doctor versions. Fact loads resolve source IDs at the relevant event date, join visits with their bills, and calculate measures. |
| `project_reporting` | Views `q1` through `q10` reuse the Phase 1 queries. The `data_quality` table records the actual and expected results for each check. |

## Run locally

Run these commands from the project root in PowerShell 7 with Python 3 and PostgreSQL 18 installed:

```powershell
.\phase2\sandbox.ps1
$env:DWBI_PSQL = 'C:/Program Files/PostgreSQL/18/bin/psql.exe'
python .\phase2\run_etl.py
```

The sandbox listens on `127.0.0.1:55432`. It uses database `hospital_dw` and role `dwbi`. Its data and generated password live under the ignored `.sandbox` folder. Pass `-PgBin` to `sandbox.ps1` and set `DWBI_PSQL` to the matching `psql.exe` if PostgreSQL is installed elsewhere.

The ETL replaces the Phase 2 snapshot in a single transaction. A failed check rolls the load back. Surrogate keys are assigned deterministically within the snapshot, so adding source records can change existing key numbers on a future full reload. Run this loader only against the project sandbox or a dedicated project database.

To query the sandbox from PowerShell:

```powershell
$env:PGPASSFILE = (Resolve-Path .\phase2\.sandbox\pgpass.conf).Path
& $env:DWBI_PSQL -h 127.0.0.1 -p 55432 -U dwbi -d hospital_dw
```

```sql
select * from project_reporting.q1;
select * from project_staging.cleaning_issue order by source_name, source_row;
select * from project_reporting.data_quality order by check_name;
```

Stop PostgreSQL with `.\phase2\sandbox.ps1 -Action stop`. Run `python .\phase2\generate_sources.py` to restore the bundled synthetic CSV examples.

## Submission files

The numbered scripts in `sql/` define staging and the warehouse, load dimensions and facts, and run validation. Run them through `run_etl.py` so the CSV imports, scripts, and reporting views are applied in order.

The cleaning and quality reports are in `output/pdf/`.

[GitHub repository](https://github.com/Soban06/healthbridge-analytics-dw)
