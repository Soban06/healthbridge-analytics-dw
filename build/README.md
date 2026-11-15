# Build sources

The deliverable documents are maintained separately. This folder contains their database and diagram source code.

| File | Purpose |
| --- | --- |
| [schema.sql](schema.sql) | Create 11 dimensions, 3 fact tables, primary and foreign keys, natural-key uniqueness, flag checks and fact indexes. |
| [sample_data.sql](sample_data.sql) | Synthetic hospital data, including the exact data dictionary samples and grain-document example records. |
| [business_questions.sql](business_questions.sql) | Ten queries matching Q1-Q10 in the business questions deliverable. |
| [dbdiagram.md](dbdiagram.md) | Conceptual, logical and physical DBML models in one file. Paste each block separately into dbdiagram. |
| [architecture.md](architecture.md) | Mermaid diagrams for the proposed data flow and ETL load dependencies. |

Run these files in order in an empty database:

1. `schema.sql`
2. `sample_data.sql`
3. The individual queries in `business_questions.sql`.

Run the schema and sample inserts only once. The SQL uses explicit keys assigned by ETL and has been checked with SQLite, with foreign-key enforcement enabled. No Python or external data connection is required to load the sample.

## Sample data

The sample represents HealthBridge General Hospital from 1 January through 30 September 2026, with a reporting cutoff of 1 October 2026. All patient, doctor and transaction records are fictional. The data reproduces the dictionary sample values and the grain document's three visit, three census and three appointment examples, including their original keys, identifiers and amounts.

| Data | Included |
| --- | --- |
| Patient visits | 1,088 completed, billed encounters across all four visit types |
| Daily bed census | 8,190 rows: all 30 wards on all 273 days, with 400 beds in total each day |
| Appointments | 1,191 final outcomes across all five statuses and five channels |
| Patients | 125 natural keys, one additional SCD version and one unknown member |
| Doctors | 450 staff IDs, one additional SCD version and one unknown member |
| Departments | 25 departments and one unknown member |
| Calendar | Every date in the sample period and one unknown member |
| Time | All 96 quarter-hour slots and one unknown member |
| Visit profiles | All 80 code combinations and one unknown member |
| Diagnoses and payers | The three example diagnoses and all four payer types, plus unknown members |

The documents' annual activity and patient-count estimates are sizing assumptions, not sample row counts. This sample uses the same business rules at a smaller transaction volume. It includes positive and negative readmission cases at the 30-day boundary, patient address history, doctor promotion history, missing dates of birth, unmatched diagnoses, rescheduled bookings with new appointment rows, outstanding balances and days with no ward activity. Age, length of stay, readmissions, balances and census movements are internally consistent. Census activity represents the full synthetic hospital; the visit and appointment tables are samples, so their counts do not reconcile to the full census.

The calendar is a subset of the proposed 2020-2035 production calendar. Holiday flags use nationwide public holidays from the Cabinet Division's [2026 circular](https://cabinet.gov.pk/SiteImage/Misc/files/Holidays/2026/Public-Holidays-2026.pdf), with the subsequent [Eid-ul-Fitr](https://cabinet.gov.pk/SiteImage/Misc/files/Holidays/EidulFitr%202026.pdf), [Eid-ul-Azha](https://cabinet.gov.pk/SiteImage/Misc/files/Holidays/2026/Eid-ul-Azha-holidays-Notification-20_05_2026.pdf), [Ashura](https://cabinet.gov.pk/SiteImage/Misc/files/Press%20Release/Notification_Ashura%20Public%20Holiday,%202026.pdf) and [Eid Milad-un-Nabi](https://cabinet.gov.pk/SiteImage/Misc/files/Press%20Release/Notification-Eid-Milad-un-Nabi-2026.pdf) notifications. Optional, bank-only and local holidays are excluded.

Reserve dimension key `-1` for unknown members. Patient and Doctor natural keys repeat across SCD type 2 versions, so their unique keys include `row_effective_date`. ETL must maintain valid, non-overlapping version periods and one current version per natural key.

Fact grains:

- `fact_patient_visit`: one completed encounter with its finalised bill; transaction fact.
- `fact_bed_occupancy_daily`: one ward at the end of one day; periodic snapshot.
- `fact_appointment`: one booked appointment with its final outcome; factless event fact.

Query conventions:

- Q1 groups visits and billed revenue by discharge month.
- Q3 measures flagged readmissions as a share of completed inpatient visits, as defined in the deliverable.
- Q4 includes ties at rank five.
- Q8 uses the 2026 census and calculates aggregate occupancy from summed bed counts.
- Q9 excludes cancelled and rescheduled appointments from the no-show denominator; cancellation rate uses all appointments.
- SQL keywords are lowercase; quoted data values retain the case used in the deliverables.
