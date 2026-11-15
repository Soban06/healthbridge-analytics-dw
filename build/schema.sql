-- dimension keys are assigned during etl; reserve -1 for unknown members.

create table dim_date (
    date_key                   int            not null,
    full_date                  date           not null,
    day_of_month               smallint       not null,
    day_name                   varchar(10)    not null,
    day_of_week                smallint       not null,
    is_weekend                 smallint       not null,
    week_of_year               smallint       not null,
    month_number               smallint       not null,
    month_name                 varchar(10)    not null,
    year_month                 char(7)        not null,
    quarter_number             smallint       not null,
    quarter_name               char(2)        not null,
    year_number                smallint       not null,
    season                     varchar(10)    not null,
    is_public_holiday          smallint       not null,
    constraint pk_dim_date primary key (date_key),
    constraint uq_dim_date_nk unique (full_date),
    constraint ck_dim_date_is_weekend check (is_weekend in (0, 1)),
    constraint ck_dim_date_is_public_holiday check (is_public_holiday in (0, 1))
);

create table dim_time (
    time_key                   smallint       not null,
    time_label                 char(5)        not null,
    hour_24                    smallint       not null,
    minute_of_hour             smallint       not null,
    hour_label                 varchar(11)    not null,
    am_pm                      char(2)        not null,
    day_part                   varchar(10)    not null,
    hospital_shift             varchar(10)    not null,
    constraint pk_dim_time primary key (time_key),
    constraint uq_dim_time_nk unique (time_label)
);

create table dim_patient (
    patient_key                int            not null,
    patient_mrn                varchar(20)    not null,
    patient_full_name          varchar(100)   not null,
    gender                     varchar(10)    not null,
    date_of_birth              date           null,
    blood_group                varchar(7)     not null,
    marital_status             varchar(15)    not null,
    city                       varchar(50)    not null,
    province                   varchar(50)    not null,
    country                    varchar(50)    not null,
    registration_date          date           not null,
    row_effective_date         date           not null,
    row_expiry_date            date           not null,
    is_current                 smallint       not null,
    constraint pk_dim_patient primary key (patient_key),
    constraint uq_dim_patient_nk unique (patient_mrn, row_effective_date),
    constraint ck_dim_patient_is_current check (is_current in (0, 1))
);

create table dim_doctor (
    doctor_key                 int            not null,
    doctor_id                  varchar(20)    not null,
    doctor_full_name           varchar(100)   not null,
    gender                     varchar(10)    not null,
    specialization             varchar(50)    not null,
    designation                varchar(30)    not null,
    qualification              varchar(100)   not null,
    employment_type            varchar(20)    not null,
    joining_date               date           not null,
    row_effective_date         date           not null,
    row_expiry_date            date           not null,
    is_current                 smallint       not null,
    constraint pk_dim_doctor primary key (doctor_key),
    constraint uq_dim_doctor_nk unique (doctor_id, row_effective_date),
    constraint ck_dim_doctor_is_current check (is_current in (0, 1))
);

create table dim_department (
    department_key             smallint       not null,
    department_code            varchar(10)    not null,
    department_name            varchar(60)    not null,
    department_category        varchar(40)    not null,
    building_name              varchar(50)    not null,
    floor_number               smallint       not null,
    has_inpatient_beds         smallint       not null,
    constraint pk_dim_department primary key (department_key),
    constraint uq_dim_department_nk unique (department_code),
    constraint ck_dim_department_has_inpatient_beds check (has_inpatient_beds in (0, 1))
);

create table dim_ward (
    ward_key                   smallint       not null,
    ward_code                  varchar(15)    not null,
    ward_name                  varchar(60)    not null,
    ward_type                  varchar(20)    not null,
    building_name              varchar(50)    not null,
    floor_number               smallint       not null,
    is_isolation_ward          smallint       not null,
    constraint pk_dim_ward primary key (ward_key),
    constraint uq_dim_ward_nk unique (ward_code),
    constraint ck_dim_ward_is_isolation_ward check (is_isolation_ward in (0, 1))
);

create table dim_diagnosis (
    diagnosis_key              int            not null,
    icd10_code                 varchar(10)    not null,
    diagnosis_description      varchar(200)   not null,
    diagnosis_block            varchar(150)   not null,
    icd10_chapter              varchar(150)   not null,
    is_chronic                 smallint       not null,
    is_communicable            smallint       not null,
    constraint pk_dim_diagnosis primary key (diagnosis_key),
    constraint uq_dim_diagnosis_nk unique (icd10_code),
    constraint ck_dim_diagnosis_is_chronic check (is_chronic in (0, 1)),
    constraint ck_dim_diagnosis_is_communicable check (is_communicable in (0, 1))
);

create table dim_payer (
    payer_key                  smallint       not null,
    payer_code                 varchar(15)    not null,
    payer_name                 varchar(80)    not null,
    payer_type                 varchar(30)    not null,
    default_coverage_pct       decimal(5,2)   not null,
    constraint pk_dim_payer primary key (payer_key),
    constraint uq_dim_payer_nk unique (payer_code)
);

create table dim_visit_profile (
    visit_profile_key          smallint       not null,
    visit_type                 varchar(20)    not null,
    admission_source           varchar(20)    not null,
    discharge_status           varchar(30)    not null,
    constraint pk_dim_visit_profile primary key (visit_profile_key),
    constraint uq_dim_visit_profile_nk unique (visit_type, admission_source, discharge_status)
);

create table dim_appointment_status (
    appointment_status_key     smallint       not null,
    status_code                varchar(10)    not null,
    status_name                varchar(30)    not null,
    status_category            varchar(20)    not null,
    is_attended                smallint       not null,
    constraint pk_dim_appointment_status primary key (appointment_status_key),
    constraint uq_dim_appointment_status_nk unique (status_code),
    constraint ck_dim_appointment_status_is_attended check (is_attended in (0, 1))
);

create table dim_booking_channel (
    booking_channel_key        smallint       not null,
    channel_code               varchar(10)    not null,
    channel_name               varchar(30)    not null,
    channel_type               varchar(20)    not null,
    constraint pk_dim_booking_channel primary key (booking_channel_key),
    constraint uq_dim_booking_channel_nk unique (channel_code)
);

-- transaction fact table: one row per completed patient visit (encounter) with its finalised bill.
create table fact_patient_visit (
    visit_number               varchar(20)    not null,
    admission_date_key         int            not null,
    discharge_date_key         int            not null,
    patient_key                int            not null,
    doctor_key                 int            not null,
    department_key             smallint       not null,
    diagnosis_key              int            not null,
    payer_key                  smallint       not null,
    visit_profile_key          smallint       not null,
    age_at_visit_years         smallint       null,
    length_of_stay_days        smallint       not null,
    wait_time_minutes          smallint       not null,
    procedure_count            smallint       not null,
    lab_test_count             smallint       not null,
    total_charge_amount        decimal(12,2)  not null,
    insurance_covered_amount   decimal(12,2)  not null,
    patient_paid_amount        decimal(12,2)  not null,
    outstanding_amount         decimal(12,2)  not null,
    readmission_30d_flag       smallint       not null,
    constraint pk_fact_patient_visit primary key (visit_number),
    constraint ck_fact_patient_visit_readmission_30d_flag check (readmission_30d_flag in (0, 1)),
    constraint fk_fact_patient_visit_admission_date_key foreign key (admission_date_key) references dim_date (date_key),
    constraint fk_fact_patient_visit_discharge_date_key foreign key (discharge_date_key) references dim_date (date_key),
    constraint fk_fact_patient_visit_patient_key foreign key (patient_key) references dim_patient (patient_key),
    constraint fk_fact_patient_visit_doctor_key foreign key (doctor_key) references dim_doctor (doctor_key),
    constraint fk_fact_patient_visit_department_key foreign key (department_key) references dim_department (department_key),
    constraint fk_fact_patient_visit_diagnosis_key foreign key (diagnosis_key) references dim_diagnosis (diagnosis_key),
    constraint fk_fact_patient_visit_payer_key foreign key (payer_key) references dim_payer (payer_key),
    constraint fk_fact_patient_visit_visit_profile_key foreign key (visit_profile_key) references dim_visit_profile (visit_profile_key)
);

-- periodic snapshot fact table: one row per ward per day (end-of-day bed census).
create table fact_bed_occupancy_daily (
    snapshot_date_key          int            not null,
    ward_key                   smallint       not null,
    department_key             smallint       not null,
    total_beds                 smallint       not null,
    occupied_beds              smallint       not null,
    available_beds             smallint       not null,
    admissions_count           smallint       not null,
    discharges_count           smallint       not null,
    occupancy_rate_pct         decimal(5,2)   not null,
    constraint pk_fact_bed_occupancy_daily primary key (snapshot_date_key, ward_key),
    constraint fk_fact_bed_occupancy_daily_snapshot_date_key foreign key (snapshot_date_key) references dim_date (date_key),
    constraint fk_fact_bed_occupancy_daily_ward_key foreign key (ward_key) references dim_ward (ward_key),
    constraint fk_fact_bed_occupancy_daily_department_key foreign key (department_key) references dim_department (department_key)
);

-- factless fact table (event tracking): one row per booked outpatient appointment (with its final outcome).
create table fact_appointment (
    appointment_number         varchar(20)    not null,
    appointment_date_key       int            not null,
    booking_date_key           int            not null,
    appointment_time_key       smallint       not null,
    patient_key                int            not null,
    doctor_key                 int            not null,
    department_key             smallint       not null,
    appointment_status_key     smallint       not null,
    booking_channel_key        smallint       not null,
    constraint pk_fact_appointment primary key (appointment_number),
    constraint fk_fact_appointment_appointment_date_key foreign key (appointment_date_key) references dim_date (date_key),
    constraint fk_fact_appointment_booking_date_key foreign key (booking_date_key) references dim_date (date_key),
    constraint fk_fact_appointment_appointment_time_key foreign key (appointment_time_key) references dim_time (time_key),
    constraint fk_fact_appointment_patient_key foreign key (patient_key) references dim_patient (patient_key),
    constraint fk_fact_appointment_doctor_key foreign key (doctor_key) references dim_doctor (doctor_key),
    constraint fk_fact_appointment_department_key foreign key (department_key) references dim_department (department_key),
    constraint fk_fact_appointment_appointment_status_key foreign key (appointment_status_key) references dim_appointment_status (appointment_status_key),
    constraint fk_fact_appointment_booking_channel_key foreign key (booking_channel_key) references dim_booking_channel (booking_channel_key)
);

create index ix_fact_patient_visit_admission_date_key on fact_patient_visit (admission_date_key);
create index ix_fact_patient_visit_discharge_date_key on fact_patient_visit (discharge_date_key);
create index ix_fact_patient_visit_patient_key on fact_patient_visit (patient_key);
create index ix_fact_patient_visit_doctor_key on fact_patient_visit (doctor_key);
create index ix_fact_patient_visit_department_key on fact_patient_visit (department_key);
create index ix_fact_patient_visit_diagnosis_key on fact_patient_visit (diagnosis_key);
create index ix_fact_patient_visit_payer_key on fact_patient_visit (payer_key);
create index ix_fact_patient_visit_visit_profile_key on fact_patient_visit (visit_profile_key);
create index ix_fact_bed_occupancy_daily_ward_key on fact_bed_occupancy_daily (ward_key);
create index ix_fact_bed_occupancy_daily_department_key on fact_bed_occupancy_daily (department_key);
create index ix_fact_appointment_appointment_date_key on fact_appointment (appointment_date_key);
create index ix_fact_appointment_booking_date_key on fact_appointment (booking_date_key);
create index ix_fact_appointment_appointment_time_key on fact_appointment (appointment_time_key);
create index ix_fact_appointment_patient_key on fact_appointment (patient_key);
create index ix_fact_appointment_doctor_key on fact_appointment (doctor_key);
create index ix_fact_appointment_department_key on fact_appointment (department_key);
create index ix_fact_appointment_appointment_status_key on fact_appointment (appointment_status_key);
create index ix_fact_appointment_booking_channel_key on fact_appointment (booking_channel_key);
