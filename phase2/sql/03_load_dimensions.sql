truncate fact_patient_visit, fact_bed_occupancy_daily, fact_appointment,
    dim_date, dim_time, dim_patient, dim_doctor, dim_department, dim_ward,
    dim_diagnosis, dim_payer, dim_visit_profile, dim_appointment_status, dim_booking_channel;

insert into dim_date values (-1, '1900-01-01', 0, 'Unknown', 0, 0, 0, 0, 'Unknown', '0000-00', 0, 'NA', 0, 'Unknown', 0);
insert into dim_time values (-1, '--:--', 0, 0, 'Unknown', 'NA', 'Unknown', 'Unknown');
insert into dim_patient values (-1, 'Unknown', 'Unknown', 'Unknown', null, 'Unknown', 'Unknown', 'Unknown', 'Unknown', 'Unknown', '1900-01-01', '1900-01-01', '9999-12-31', 1);
insert into dim_doctor values (-1, 'Unknown', 'Unknown', 'Unknown', 'Unknown', 'Unknown', 'Unknown', 'Unknown', '1900-01-01', '1900-01-01', '9999-12-31', 1);
insert into dim_department values (-1, 'Unknown', 'Unknown', 'Unknown', 'Unknown', 0, 0);
insert into dim_ward values (-1, 'Unknown', 'Unknown', 'Unknown', 'Unknown', 0, 0);
insert into dim_diagnosis values (-1, 'Unknown', 'Unknown', 'Unknown', 'Unknown', 0, 0);
insert into dim_payer values (-1, 'Unknown', 'Unknown', 'Unknown', 0);
insert into dim_visit_profile values (-1, 'Unknown', 'Unknown', 'Unknown');
insert into dim_appointment_status values (-1, 'Unknown', 'Unknown', 'Unknown', 0);
insert into dim_booking_channel values (-1, 'Unknown', 'Unknown', 'Unknown');

insert into dim_date
select to_char(full_date, 'YYYYMMDD')::int, full_date, extract(day from full_date),
       to_char(full_date, 'FMDay'), extract(isodow from full_date),
       (extract(isodow from full_date) >= 6)::int, extract(week from full_date),
       extract(month from full_date), to_char(full_date, 'FMMonth'), to_char(full_date, 'YYYY-MM'),
       extract(quarter from full_date), to_char(full_date, '"Q"Q'), extract(year from full_date),
       case extract(month from full_date)::int
           when 12 then 'Winter' when 1 then 'Winter' when 2 then 'Winter'
           when 3 then 'Spring' when 4 then 'Spring' when 5 then 'Summer' when 6 then 'Summer'
           when 7 then 'Monsoon' when 8 then 'Monsoon' when 9 then 'Monsoon' else 'Autumn'
       end, is_public_holiday
from project_staging.stg_calendar;

insert into dim_time
select h * 100 + m, to_char(make_time(h, m, 0), 'HH24:MI'), h, m,
       lpad(h::text, 2, '0') || ':00-' || lpad(h::text, 2, '0') || ':59',
       case when h < 12 then 'AM' else 'PM' end,
       case when h between 6 and 11 then 'Morning' when h between 12 and 16 then 'Afternoon'
            when h between 17 and 20 then 'Evening' else 'Night' end,
       case when h between 8 and 15 then 'Morning' when h >= 16 then 'Evening' else 'Night' end
from generate_series(0, 23) as hours(h)
cross join generate_series(0, 45, 15) as minutes(m);

-- close each historical version the day before the next version takes effect.
insert into dim_patient
select row_number() over (order by patient_mrn, row_effective_date),
       patient_mrn, patient_full_name, gender, date_of_birth, blood_group, marital_status,
       city, province, country, registration_date, row_effective_date,
       coalesce(next_effective - 1, date '9999-12-31'), (next_effective is null)::int
from (
    select p.*, lead(row_effective_date) over (partition by patient_mrn order by row_effective_date) as next_effective
    from project_staging.stg_patients p
) versions;

insert into dim_doctor
select row_number() over (order by doctor_id, row_effective_date),
       doctor_id, doctor_full_name, gender, specialization, designation, qualification,
       employment_type, joining_date, row_effective_date,
       coalesce(next_effective - 1, date '9999-12-31'), (next_effective is null)::int
from (
    select d.*, lead(row_effective_date) over (partition by doctor_id order by row_effective_date) as next_effective
    from project_staging.stg_doctors d
) versions;

insert into dim_department select row_number() over (order by department_code), d.* from project_staging.stg_departments d;
insert into dim_ward select row_number() over (order by ward_code), w.* from project_staging.stg_wards w;
insert into dim_diagnosis select row_number() over (order by icd10_code), d.* from project_staging.stg_diagnoses d;
insert into dim_payer select row_number() over (order by payer_code), p.* from project_staging.stg_payers p;
insert into dim_visit_profile select row_number() over (order by visit_type, admission_source, discharge_status), p.* from project_staging.stg_visit_profiles p;
insert into dim_appointment_status select row_number() over (order by status_code), s.* from project_staging.stg_appointment_statuses s;
insert into dim_booking_channel select row_number() over (order by channel_code), c.* from project_staging.stg_booking_channels c;
