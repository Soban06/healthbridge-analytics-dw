# Phase 3 deliverables

Phase 3 turns the Phase 2 warehouse into a decision-support system with analytical SQL, OLAP queries, reporting views, indexing and a Power BI dashboard.

| Deliverable | File |
| --- | --- |
| Analytical SQL queries | [01_Analytical_SQL_Queries.sql](01_Analytical_SQL_Queries.sql) |
| OLAP queries (ROLLUP and CUBE) | [02_OLAP_Queries.sql](02_OLAP_Queries.sql) |
| Reporting views | [03_Reporting_Views.sql](03_Reporting_Views.sql) |
| Query optimization script | [04_Query_Optimization.sql](04_Query_Optimization.sql) |
| Indexing report | [05_Indexing_Report.pdf](05_Indexing_Report.pdf) |
| Power BI dashboard | [06_Power_BI_Dashboard.pbix](06_Power_BI_Dashboard.pbix) |
| Dashboard screenshots | [07_Dashboard_Screenshots.pdf](07_Dashboard_Screenshots.pdf) |
| Business insights report | [08_Business_Insights_Report.pdf](08_Business_Insights_Report.pdf) |
| Final presentation | [09_Final_Presentation.pptx](09_Final_Presentation.pptx) |

## Run the SQL

Load the warehouse first with the [Phase 2 instructions](../phase2/README.md#run-locally). Then run the scripts from the project root in PowerShell:

```powershell
$env:PGPASSFILE = (Resolve-Path .\phase2\.sandbox\pgpass.conf).Path
foreach ($f in '01_Analytical_SQL_Queries', '02_OLAP_Queries', '03_Reporting_Views', '04_Query_Optimization') {
    & $env:DWBI_PSQL -h 127.0.0.1 -p 55432 -U dwbi -d hospital_dw -v ON_ERROR_STOP=1 -f ".\Phase 3 Deliverables\$f.sql"
}
```

`03_Reporting_Views.sql` creates the views in `project_reporting`. The Power BI dashboard reads them, so run it before refreshing the dashboard. `04_Query_Optimization.sql` drops and recreates its two indexes, so it can be re-run to compare the plans again.

## Dashboard

The dashboard imports the three reporting views plus `fact_patient_visit`, `dim_patient`, `dim_payer` and `dim_visit_profile` from `hospital_dw` at `127.0.0.1:55432`. The PBIX already contains the loaded data. To refresh it, select **Refresh** and sign in with the **Database** credentials of the sandbox role `dwbi`.

| Page | Contents |
| --- | --- |
| Executive Overview | Revenue, orders (patient visits) and customers (unique patients) KPIs, the monthly sales trend, and a month, revenue and growth table |
| Detailed Analysis | Revenue by department, revenue by patient province, and customer value segments |
| Decision Page | Outstanding balances by payer type and management's decision |
