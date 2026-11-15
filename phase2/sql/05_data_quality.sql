truncate project_reporting.data_quality;

insert into project_reporting.data_quality (check_name, actual, expected)
select 'raw rows accounted for', (select count(*) from project_staging.raw_source),
       (select sum(clean_rows + duplicates + rejected) from project_staging.load_summary)
union all
select 'cleaning issues accounted for', (select count(*) from project_staging.cleaning_issue),
       (select sum(duplicates + rejected) from project_staging.load_summary)
union all
select 'accepted visits loaded', (select count(*) from fact_patient_visit),
       (select count(*) from project_staging.stg_visits)
union all
select 'accepted bills loaded', (select count(*) from fact_patient_visit),
       (select count(*) from project_staging.stg_billing)
union all
select 'accepted ward snapshots loaded', (select count(*) from fact_bed_occupancy_daily),
       (select count(*) from project_staging.stg_bed_census)
union all
select 'accepted appointments loaded', (select count(*) from fact_appointment),
       (select count(*) from project_staging.stg_appointments)
union all
select 'minimum dimension volume met', ((
    (select count(*) from dim_date where date_key <> -1) +
    (select count(*) from dim_time where time_key <> -1) +
    (select sum(clean_rows) from project_staging.load_summary where source_name in (
        'patients', 'doctors', 'departments', 'wards', 'diagnoses', 'payers',
        'visit_profiles', 'appointment_statuses', 'booking_channels'
    ))) >= 100)::int, 1
union all
select 'minimum fact volume met', ((
    (select count(*) from fact_patient_visit) +
    (select count(*) from fact_bed_occupancy_daily) +
    (select count(*) from fact_appointment)) >= 10000)::int, 1
union all
select 'total billed reconciles', coalesce((select sum(total_charge_amount) from fact_patient_visit), 0),
       coalesce((select sum(total_charge_amount) from project_staging.stg_billing), 0)
union all
select 'payer coverage reconciles', coalesce((select sum(insurance_covered_amount) from fact_patient_visit), 0),
       coalesce((select sum(insurance_covered_amount) from project_staging.stg_billing), 0)
union all
select 'patient payments reconcile', coalesce((select sum(patient_paid_amount) from fact_patient_visit), 0),
       coalesce((select sum(patient_paid_amount) from project_staging.stg_billing), 0)
union all
select 'outstanding balance reconciles', coalesce((select sum(outstanding_amount) from fact_patient_visit), 0),
       coalesce((select sum(total_charge_amount - insurance_covered_amount - patient_paid_amount) from project_staging.stg_billing), 0)
union all
select 'invalid visit balances', count(*), 0 from fact_patient_visit
where outstanding_amount < 0 or outstanding_amount <> total_charge_amount - insurance_covered_amount - patient_paid_amount
union all
select 'invalid ward balances', count(*), 0 from fact_bed_occupancy_daily
where available_beds <> total_beds - occupied_beds or available_beds < 0
union all
select 'invalid appointment dates', count(*), 0 from fact_appointment where booking_date_key > appointment_date_key
union all
select 'invalid patient versions', count(*), 0 from (
    select patient_mrn from dim_patient group by patient_mrn having sum(is_current) <> 1
) bad_patient
union all
select 'invalid doctor versions', count(*), 0 from (
    select doctor_id from dim_doctor group by doctor_id having sum(is_current) <> 1
) bad_doctor
union all
select 'unvalidated fact foreign keys', count(*), 0 from pg_constraint
where connamespace = 'project_dw'::regnamespace and contype = 'f' and not convalidated
union all
select 'fact foreign keys installed', count(*), 19 from pg_constraint
where connamespace = 'project_dw'::regnamespace and contype = 'f'
union all
select 'current patient versions without dates of birth', count(*),
       (select count(*) from project_staging.stg_patients p where p.date_of_birth is null and not exists (
           select 1 from project_staging.stg_patients later
           where later.patient_mrn = p.patient_mrn and later.row_effective_date > p.row_effective_date
       ))
from dim_patient where patient_key <> -1 and is_current = 1 and date_of_birth is null
union all
select 'visits with missing or unmatched diagnosis', (select count(*) from fact_patient_visit where diagnosis_key = -1),
       (select count(*) from project_staging.stg_visits v left join dim_diagnosis d on d.icd10_code = v.icd10_code where d.diagnosis_key is null)
union all
select 'reporting views return data',
       (exists (select 1 from project_reporting.q1))::int + (exists (select 1 from project_reporting.q2))::int +
       (exists (select 1 from project_reporting.q3))::int + (exists (select 1 from project_reporting.q4))::int +
       (exists (select 1 from project_reporting.q5))::int + (exists (select 1 from project_reporting.q6))::int +
       (exists (select 1 from project_reporting.q7))::int + (exists (select 1 from project_reporting.q8))::int +
       (exists (select 1 from project_reporting.q9))::int + (exists (select 1 from project_reporting.q10))::int, 10;

do $$
declare
    failures text;
begin
    select string_agg(check_name, ', ' order by check_name) into failures
    from project_reporting.data_quality where not passed;
    if failures is not null then
        raise exception 'warehouse validation failed: %', failures;
    end if;
end
$$;
