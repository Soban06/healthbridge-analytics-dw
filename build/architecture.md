# Warehouse architecture

These Mermaid diagrams describe the proposed design for the project proposal and business requirements. Loads run daily (T+1).

## Data flow

```mermaid
flowchart LR
    subgraph sources [Source systems]
        registration[HMIS patient registration]
        adt[HMIS admissions and discharges]
        billing[HMIS billing]
        beds[Bed management]
        appointments[Appointment scheduling]
        hr[HR doctor records]
        reference[ICD-10 and holiday reference data]
    end

    subgraph staging [Staging area]
        raw[Daily raw extracts]
    end

    subgraph integration [ETL]
        clean[Validate and standardise]
        conform[Conform dimensions and resolve keys]
        history[Apply SCD types 1 and 2]
        derive[Derive measures and final outcomes]
    end

    subgraph warehouse [Hospital analytics warehouse]
        dimensions[11 dimension tables]
        visits[fact_patient_visit]
        census[fact_bed_occupancy_daily]
        bookings[fact_appointment]
    end

    subgraph analytics [BI and OLAP]
        queries[Business question SQL]
        reports[Power BI KPI dashboards]
        exploration[Drill-down and drill-across]
    end

    registration --> raw
    adt --> raw
    billing --> raw
    beds --> raw
    appointments --> raw
    hr --> raw
    reference --> raw
    raw --> clean --> conform --> history --> derive
    history --> dimensions
    derive --> visits
    derive --> census
    derive --> bookings
    dimensions --> queries
    visits --> queries
    census --> queries
    bookings --> queries
    queries --> reports
    queries --> exploration
```

## Load dependencies

```mermaid
flowchart TD
    calendar[Generate date and 15-minute time dimensions]
    extracted[Validate daily source extracts]
    dimensions[Load dimensions before facts]
    unknown[Create unknown members with key -1]
    patient[Patient SCD type 2 history]
    doctor[Doctor SCD type 2 history]
    lookup[Resolve dimension keys at the relevant event date]
    visit[Completed visits with finalised bills]
    census[One census per ward per calendar day]
    appointment[Appointments with final outcomes after the scheduled date]
    measures[Derive age, length of stay, balances and readmission flags]
    checks[Check grain uniqueness and foreign keys]
    publish[Make validated warehouse data available to BI]

    calendar --> dimensions
    extracted --> dimensions
    dimensions --> unknown
    dimensions --> patient
    dimensions --> doctor
    unknown --> lookup
    patient --> lookup
    doctor --> lookup
    lookup --> visit
    lookup --> census
    lookup --> appointment
    visit --> measures
    measures --> checks
    census --> checks
    appointment --> checks
    checks --> publish
```

Patient versions are selected at admission for visits and at the scheduled appointment date for appointments. Doctor versions follow the responsible doctor at discharge for visits and the scheduled date for appointments. Unknown keys are used when a dimension lookup cannot be resolved.

Date, Patient, Doctor and Department are conformed dimensions. Compare business processes by aggregating each fact table to the required shared dimension level before joining results.
