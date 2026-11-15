create schema if not exists project_staging;

create table if not exists project_staging.raw_source (
    source_name text not null,
    source_row integer not null,
    payload jsonb not null,
    primary key (source_name, source_row)
);

create table if not exists project_staging.cleaning_issue (
    source_name text not null,
    source_row integer not null,
    disposition text not null check (disposition in ('duplicate', 'rejected')),
    reason text not null,
    primary key (source_name, source_row),
    foreign key (source_name, source_row) references project_staging.raw_source
);

create table if not exists project_staging.load_summary (
    source_name text primary key,
    input_rows integer not null,
    clean_rows integer not null,
    duplicates integer not null,
    rejected integer not null,
    check (input_rows = clean_rows + duplicates + rejected)
);

create table if not exists project_staging.stg_patients (
    patient_mrn varchar(20), patient_full_name varchar(100), gender varchar(10),
    date_of_birth date, blood_group varchar(7), marital_status varchar(15),
    city varchar(50), province varchar(50), country varchar(50),
    registration_date date, row_effective_date date,
    primary key (patient_mrn, row_effective_date)
);

create table if not exists project_staging.stg_doctors (
    doctor_id varchar(20), doctor_full_name varchar(100), gender varchar(10),
    specialization varchar(50), designation varchar(30), qualification varchar(100),
    employment_type varchar(20), joining_date date, row_effective_date date,
    primary key (doctor_id, row_effective_date)
);

create table if not exists project_staging.stg_departments (
    department_code varchar(10) primary key, department_name varchar(60),
    department_category varchar(40), building_name varchar(50), floor_number smallint,
    has_inpatient_beds smallint
);

create table if not exists project_staging.stg_wards (
    ward_code varchar(15) primary key, ward_name varchar(60), ward_type varchar(20),
    building_name varchar(50), floor_number smallint, is_isolation_ward smallint
);

create table if not exists project_staging.stg_diagnoses (
    icd10_code varchar(10) primary key, diagnosis_description varchar(200),
    diagnosis_block varchar(150), icd10_chapter varchar(150), is_chronic smallint,
    is_communicable smallint
);

create table if not exists project_staging.stg_payers (
    payer_code varchar(15) primary key, payer_name varchar(80), payer_type varchar(30),
    default_coverage_pct numeric(5,2)
);

create table if not exists project_staging.stg_visit_profiles (
    visit_type varchar(20), admission_source varchar(20), discharge_status varchar(30),
    primary key (visit_type, admission_source, discharge_status)
);

create table if not exists project_staging.stg_appointment_statuses (
    status_code varchar(10) primary key, status_name varchar(30), status_category varchar(20),
    is_attended smallint
);

create table if not exists project_staging.stg_booking_channels (
    channel_code varchar(10) primary key, channel_name varchar(30), channel_type varchar(20)
);

create table if not exists project_staging.stg_calendar (
    full_date date primary key, is_public_holiday smallint
);

create table if not exists project_staging.stg_visits (
    visit_number varchar(20) primary key, admission_date date, discharge_date date,
    patient_mrn varchar(20), doctor_id varchar(20), department_code varchar(10), icd10_code varchar(10),
    visit_type varchar(20), admission_source varchar(20), discharge_status varchar(30),
    wait_time_minutes smallint, procedure_count smallint, lab_test_count smallint
);

create table if not exists project_staging.stg_billing (
    visit_number varchar(20) primary key, payer_code varchar(15), total_charge_amount numeric(12,2),
    insurance_covered_amount numeric(12,2), patient_paid_amount numeric(12,2)
);

create table if not exists project_staging.stg_bed_census (
    snapshot_date date, ward_code varchar(15), department_code varchar(10), total_beds smallint,
    occupied_beds smallint, admissions_count smallint, discharges_count smallint,
    primary key (snapshot_date, ward_code)
);

create table if not exists project_staging.stg_appointments (
    appointment_number varchar(20) primary key, appointment_date date, booking_date date,
    appointment_time time, patient_mrn varchar(20), doctor_id varchar(20), department_code varchar(10),
    status_code varchar(10), channel_code varchar(10)
);
