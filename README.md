# HealthBridge Hospital Analytics Data Warehouse

DL3004 Data Warehousing Lab project for a fictional hospital. The warehouse models patient visits and billing, daily bed occupancy, and outpatient appointments.

| Phase | Deliverables |
| --- | --- |
| Phase 1 · Requirements and design | [Proposal, requirements, business questions, fact identification, grain definitions, schema diagrams, and data dictionary](Phase%201%20Deliverables/) |
| Phase 2 · PostgreSQL implementation | [Setup instructions, synthetic CSVs, and ETL scripts](phase2/) · [Data Cleaning Report](output/pdf/01_Data_Cleaning_Report.pdf) · [Data Quality Report](output/pdf/02_Data_Quality_Report.pdf) |
| Phase 3 · Analytics and BI | [Analytical SQL, OLAP queries, reporting views, indexing report, Power BI dashboard, screenshots, business insights, and final presentation](Phase%203%20Deliverables/) |

The pipeline reads source CSVs, cleans them in `project_staging`, loads dimensions and facts in `project_dw`, and exposes ten business question views in `project_reporting`. The PostgreSQL test load produced 1,109 dimension rows and 10,469 fact rows, and passed all 22 quality checks.

To run the pipeline locally, follow the [Phase 2 setup instructions](phase2/README.md#run-locally). The [shared SQL and diagram sources](build/) contain the physical schema and original business questions.
