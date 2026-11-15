# Dbdiagram models

Paste one complete DBML block at a time into the dbdiagram editor. Each block contains the full fact constellation.

## Conceptual

Entities and relationships; keys provide the relationship anchors required by dbdiagram.

```dbml
table "Date" {
  "Date Key" key [pk]
}

table "Time of Day" {
  "Time Key" key [pk]
}

table "Patient" {
  "Patient Key" key [pk]
}

table "Doctor" {
  "Doctor Key" key [pk]
}

table "Department" {
  "Department Key" key [pk]
}

table "Ward" {
  "Ward Key" key [pk]
}

table "Diagnosis" {
  "Diagnosis Key" key [pk]
}

table "Payer" {
  "Payer Key" key [pk]
}

table "Visit Profile" {
  "Visit Profile Key" key [pk]
}

table "Appointment Status" {
  "Appointment Status Key" key [pk]
}

table "Booking Channel" {
  "Booking Channel Key" key [pk]
}

table "Patient Visit" {
  "Visit Number" key [pk]
  "Admission Date Key" key [not null]
  "Discharge Date Key" key [not null]
  "Patient Key" key [not null]
  "Doctor Key" key [not null]
  "Department Key" key [not null]
  "Diagnosis Key" key [not null]
  "Payer Key" key [not null]
  "Visit Profile Key" key [not null]
  note: 'Transaction fact table. Grain: One row per completed patient visit (encounter) with its finalised bill.'
}

table "Daily Bed Occupancy" {
  "Snapshot Date Key" key [not null]
  "Ward Key" key [not null]
  "Department Key" key [not null]
  indexes {
    ("Snapshot Date Key", "Ward Key") [pk]
  }
  note: 'Periodic snapshot fact table. Grain: One row per ward per day (end-of-day bed census).'
}

table "Appointment" {
  "Appointment Number" key [pk]
  "Appointment Date Key" key [not null]
  "Booking Date Key" key [not null]
  "Appointment Time Key" key [not null]
  "Patient Key" key [not null]
  "Doctor Key" key [not null]
  "Department Key" key [not null]
  "Appointment Status Key" key [not null]
  "Booking Channel Key" key [not null]
  note: 'Factless fact table (event tracking). Grain: One row per booked outpatient appointment (with its final outcome).'
}

ref: "Patient Visit"."Admission Date Key" > "Date"."Date Key"
ref: "Patient Visit"."Discharge Date Key" > "Date"."Date Key"
ref: "Patient Visit"."Patient Key" > "Patient"."Patient Key"
ref: "Patient Visit"."Doctor Key" > "Doctor"."Doctor Key"
ref: "Patient Visit"."Department Key" > "Department"."Department Key"
ref: "Patient Visit"."Diagnosis Key" > "Diagnosis"."Diagnosis Key"
ref: "Patient Visit"."Payer Key" > "Payer"."Payer Key"
ref: "Patient Visit"."Visit Profile Key" > "Visit Profile"."Visit Profile Key"
ref: "Daily Bed Occupancy"."Snapshot Date Key" > "Date"."Date Key"
ref: "Daily Bed Occupancy"."Ward Key" > "Ward"."Ward Key"
ref: "Daily Bed Occupancy"."Department Key" > "Department"."Department Key"
ref: "Appointment"."Appointment Date Key" > "Date"."Date Key"
ref: "Appointment"."Booking Date Key" > "Date"."Date Key"
ref: "Appointment"."Appointment Time Key" > "Time of Day"."Time Key"
ref: "Appointment"."Patient Key" > "Patient"."Patient Key"
ref: "Appointment"."Doctor Key" > "Doctor"."Doctor Key"
ref: "Appointment"."Department Key" > "Department"."Department Key"
ref: "Appointment"."Appointment Status Key" > "Appointment Status"."Appointment Status Key"
ref: "Appointment"."Booking Channel Key" > "Booking Channel"."Booking Channel Key"
```

## Logical

Business attributes, generic data types, primary keys, foreign keys and natural keys.

```dbml
table "Date" {
  "Date Key" integer [pk, not null]
  "Full Date" date [not null]
  "Day of Month" integer [not null]
  "Day Name" text [not null]
  "Day of Week" integer [not null]
  "Weekend Flag" integer [not null]
  "Week of Year" integer [not null]
  "Month Number" integer [not null]
  "Month Name" text [not null]
  "Year-Month" text [not null]
  "Quarter Number" integer [not null]
  "Quarter Name" text [not null]
  "Year" integer [not null]
  "Season" text [not null]
  "Public Holiday Flag" integer [not null]
  indexes {
    "Full Date" [unique]
  }
}

table "Time of Day" {
  "Time Key" integer [pk, not null]
  "Time Label" text [not null]
  "Hour (24h)" integer [not null]
  "Minute" integer [not null]
  "Hour Label" text [not null]
  "AM/PM" text [not null]
  "Day Part" text [not null]
  "Hospital Shift" text [not null]
  indexes {
    "Time Label" [unique]
  }
}

table "Patient" {
  "Patient Key" integer [pk, not null]
  "Medical Record Number" text [not null]
  "Patient Name" text [not null]
  "Gender" text [not null]
  "Date of Birth" date [null]
  "Blood Group" text [not null]
  "Marital Status" text [not null]
  "City" text [not null]
  "Province" text [not null]
  "Country" text [not null]
  "Registration Date" date [not null]
  "Row Effective Date" date [not null]
  "Row Expiry Date" date [not null]
  "Current Row Flag" integer [not null]
  indexes {
    ("Medical Record Number", "Row Effective Date") [unique]
  }
}

table "Doctor" {
  "Doctor Key" integer [pk, not null]
  "Doctor ID" text [not null]
  "Doctor Name" text [not null]
  "Gender" text [not null]
  "Specialization" text [not null]
  "Designation" text [not null]
  "Qualification" text [not null]
  "Employment Type" text [not null]
  "Joining Date" date [not null]
  "Row Effective Date" date [not null]
  "Row Expiry Date" date [not null]
  "Current Row Flag" integer [not null]
  indexes {
    ("Doctor ID", "Row Effective Date") [unique]
  }
}

table "Department" {
  "Department Key" integer [pk, not null]
  "Department Code" text [not null]
  "Department Name" text [not null]
  "Department Category" text [not null]
  "Building" text [not null]
  "Floor" integer [not null]
  "Has Inpatient Beds" integer [not null]
  indexes {
    "Department Code" [unique]
  }
}

table "Ward" {
  "Ward Key" integer [pk, not null]
  "Ward Code" text [not null]
  "Ward Name" text [not null]
  "Ward Type" text [not null]
  "Building" text [not null]
  "Floor" integer [not null]
  "Isolation Ward Flag" integer [not null]
  indexes {
    "Ward Code" [unique]
  }
}

table "Diagnosis" {
  "Diagnosis Key" integer [pk, not null]
  "ICD-10 Code" text [not null]
  "Diagnosis Description" text [not null]
  "Diagnosis Block" text [not null]
  "ICD-10 Chapter" text [not null]
  "Chronic Condition Flag" integer [not null]
  "Communicable Disease Flag" integer [not null]
  indexes {
    "ICD-10 Code" [unique]
  }
}

table "Payer" {
  "Payer Key" integer [pk, not null]
  "Payer Code" text [not null]
  "Payer Name" text [not null]
  "Payer Type" text [not null]
  "Default Coverage %" decimal [not null]
  indexes {
    "Payer Code" [unique]
  }
}

table "Visit Profile" {
  "Visit Profile Key" integer [pk, not null]
  "Visit Type" text [not null]
  "Admission Source" text [not null]
  "Discharge Status" text [not null]
  indexes {
    ("Visit Type", "Admission Source", "Discharge Status") [unique]
  }
}

table "Appointment Status" {
  "Appointment Status Key" integer [pk, not null]
  "Status Code" text [not null]
  "Status Name" text [not null]
  "Status Category" text [not null]
  "Attended Flag" integer [not null]
  indexes {
    "Status Code" [unique]
  }
}

table "Booking Channel" {
  "Booking Channel Key" integer [pk, not null]
  "Channel Code" text [not null]
  "Channel Name" text [not null]
  "Channel Type" text [not null]
  indexes {
    "Channel Code" [unique]
  }
}

table "Patient Visit" {
  "Visit Number" text [pk, not null]
  "Admission Date Key" integer [not null]
  "Discharge Date Key" integer [not null]
  "Patient Key" integer [not null]
  "Doctor Key" integer [not null]
  "Department Key" integer [not null]
  "Diagnosis Key" integer [not null]
  "Payer Key" integer [not null]
  "Visit Profile Key" integer [not null]
  "Age at Visit (Years)" integer [null]
  "Length of Stay (Days)" integer [not null]
  "Wait Time (Minutes)" integer [not null]
  "Procedure Count" integer [not null]
  "Lab Test Count" integer [not null]
  "Total Charge (PKR)" decimal [not null]
  "Insurance Covered (PKR)" decimal [not null]
  "Patient Paid (PKR)" decimal [not null]
  "Outstanding (PKR)" decimal [not null]
  "30-Day Readmission Flag" integer [not null]
  note: 'Transaction fact table. Grain: One row per completed patient visit (encounter) with its finalised bill.'
}

table "Daily Bed Occupancy" {
  "Snapshot Date Key" integer [not null]
  "Ward Key" integer [not null]
  "Department Key" integer [not null]
  "Total Beds" integer [not null]
  "Occupied Beds" integer [not null]
  "Available Beds" integer [not null]
  "Admissions" integer [not null]
  "Discharges" integer [not null]
  "Occupancy Rate %" decimal [not null]
  indexes {
    ("Snapshot Date Key", "Ward Key") [pk]
  }
  note: 'Periodic snapshot fact table. Grain: One row per ward per day (end-of-day bed census).'
}

table "Appointment" {
  "Appointment Number" text [pk, not null]
  "Appointment Date Key" integer [not null]
  "Booking Date Key" integer [not null]
  "Appointment Time Key" integer [not null]
  "Patient Key" integer [not null]
  "Doctor Key" integer [not null]
  "Department Key" integer [not null]
  "Appointment Status Key" integer [not null]
  "Booking Channel Key" integer [not null]
  note: 'Factless fact table (event tracking). Grain: One row per booked outpatient appointment (with its final outcome).'
}

ref: "Patient Visit"."Admission Date Key" > "Date"."Date Key"
ref: "Patient Visit"."Discharge Date Key" > "Date"."Date Key"
ref: "Patient Visit"."Patient Key" > "Patient"."Patient Key"
ref: "Patient Visit"."Doctor Key" > "Doctor"."Doctor Key"
ref: "Patient Visit"."Department Key" > "Department"."Department Key"
ref: "Patient Visit"."Diagnosis Key" > "Diagnosis"."Diagnosis Key"
ref: "Patient Visit"."Payer Key" > "Payer"."Payer Key"
ref: "Patient Visit"."Visit Profile Key" > "Visit Profile"."Visit Profile Key"
ref: "Daily Bed Occupancy"."Snapshot Date Key" > "Date"."Date Key"
ref: "Daily Bed Occupancy"."Ward Key" > "Ward"."Ward Key"
ref: "Daily Bed Occupancy"."Department Key" > "Department"."Department Key"
ref: "Appointment"."Appointment Date Key" > "Date"."Date Key"
ref: "Appointment"."Booking Date Key" > "Date"."Date Key"
ref: "Appointment"."Appointment Time Key" > "Time of Day"."Time Key"
ref: "Appointment"."Patient Key" > "Patient"."Patient Key"
ref: "Appointment"."Doctor Key" > "Doctor"."Doctor Key"
ref: "Appointment"."Department Key" > "Department"."Department Key"
ref: "Appointment"."Appointment Status Key" > "Appointment Status"."Appointment Status Key"
ref: "Appointment"."Booking Channel Key" > "Booking Channel"."Booking Channel Key"
```

## Physical

SQL table and column names, data types, nullability and key constraints. Additional flag checks and foreign-key indexes are defined in schema.sql.

```dbml
table dim_date {
  date_key int [pk, not null]
  full_date date [not null]
  day_of_month smallint [not null]
  day_name varchar(10) [not null]
  day_of_week smallint [not null]
  is_weekend smallint [not null]
  week_of_year smallint [not null]
  month_number smallint [not null]
  month_name varchar(10) [not null]
  year_month char(7) [not null]
  quarter_number smallint [not null]
  quarter_name char(2) [not null]
  year_number smallint [not null]
  season varchar(10) [not null]
  is_public_holiday smallint [not null]
  indexes {
    full_date [unique]
  }
}

table dim_time {
  time_key smallint [pk, not null]
  time_label char(5) [not null]
  hour_24 smallint [not null]
  minute_of_hour smallint [not null]
  hour_label varchar(11) [not null]
  am_pm char(2) [not null]
  day_part varchar(10) [not null]
  hospital_shift varchar(10) [not null]
  indexes {
    time_label [unique]
  }
}

table dim_patient {
  patient_key int [pk, not null]
  patient_mrn varchar(20) [not null]
  patient_full_name varchar(100) [not null]
  gender varchar(10) [not null]
  date_of_birth date [null]
  blood_group varchar(7) [not null]
  marital_status varchar(15) [not null]
  city varchar(50) [not null]
  province varchar(50) [not null]
  country varchar(50) [not null]
  registration_date date [not null]
  row_effective_date date [not null]
  row_expiry_date date [not null]
  is_current smallint [not null]
  indexes {
    (patient_mrn, row_effective_date) [unique]
  }
}

table dim_doctor {
  doctor_key int [pk, not null]
  doctor_id varchar(20) [not null]
  doctor_full_name varchar(100) [not null]
  gender varchar(10) [not null]
  specialization varchar(50) [not null]
  designation varchar(30) [not null]
  qualification varchar(100) [not null]
  employment_type varchar(20) [not null]
  joining_date date [not null]
  row_effective_date date [not null]
  row_expiry_date date [not null]
  is_current smallint [not null]
  indexes {
    (doctor_id, row_effective_date) [unique]
  }
}

table dim_department {
  department_key smallint [pk, not null]
  department_code varchar(10) [not null]
  department_name varchar(60) [not null]
  department_category varchar(40) [not null]
  building_name varchar(50) [not null]
  floor_number smallint [not null]
  has_inpatient_beds smallint [not null]
  indexes {
    department_code [unique]
  }
}

table dim_ward {
  ward_key smallint [pk, not null]
  ward_code varchar(15) [not null]
  ward_name varchar(60) [not null]
  ward_type varchar(20) [not null]
  building_name varchar(50) [not null]
  floor_number smallint [not null]
  is_isolation_ward smallint [not null]
  indexes {
    ward_code [unique]
  }
}

table dim_diagnosis {
  diagnosis_key int [pk, not null]
  icd10_code varchar(10) [not null]
  diagnosis_description varchar(200) [not null]
  diagnosis_block varchar(150) [not null]
  icd10_chapter varchar(150) [not null]
  is_chronic smallint [not null]
  is_communicable smallint [not null]
  indexes {
    icd10_code [unique]
  }
}

table dim_payer {
  payer_key smallint [pk, not null]
  payer_code varchar(15) [not null]
  payer_name varchar(80) [not null]
  payer_type varchar(30) [not null]
  default_coverage_pct decimal(5,2) [not null]
  indexes {
    payer_code [unique]
  }
}

table dim_visit_profile {
  visit_profile_key smallint [pk, not null]
  visit_type varchar(20) [not null]
  admission_source varchar(20) [not null]
  discharge_status varchar(30) [not null]
  indexes {
    (visit_type, admission_source, discharge_status) [unique]
  }
}

table dim_appointment_status {
  appointment_status_key smallint [pk, not null]
  status_code varchar(10) [not null]
  status_name varchar(30) [not null]
  status_category varchar(20) [not null]
  is_attended smallint [not null]
  indexes {
    status_code [unique]
  }
}

table dim_booking_channel {
  booking_channel_key smallint [pk, not null]
  channel_code varchar(10) [not null]
  channel_name varchar(30) [not null]
  channel_type varchar(20) [not null]
  indexes {
    channel_code [unique]
  }
}

table fact_patient_visit {
  visit_number varchar(20) [pk, not null]
  admission_date_key int [not null]
  discharge_date_key int [not null]
  patient_key int [not null]
  doctor_key int [not null]
  department_key smallint [not null]
  diagnosis_key int [not null]
  payer_key smallint [not null]
  visit_profile_key smallint [not null]
  age_at_visit_years smallint [null]
  length_of_stay_days smallint [not null]
  wait_time_minutes smallint [not null]
  procedure_count smallint [not null]
  lab_test_count smallint [not null]
  total_charge_amount decimal(12,2) [not null]
  insurance_covered_amount decimal(12,2) [not null]
  patient_paid_amount decimal(12,2) [not null]
  outstanding_amount decimal(12,2) [not null]
  readmission_30d_flag smallint [not null]
  note: 'Transaction fact table. Grain: One row per completed patient visit (encounter) with its finalised bill.'
}

table fact_bed_occupancy_daily {
  snapshot_date_key int [not null]
  ward_key smallint [not null]
  department_key smallint [not null]
  total_beds smallint [not null]
  occupied_beds smallint [not null]
  available_beds smallint [not null]
  admissions_count smallint [not null]
  discharges_count smallint [not null]
  occupancy_rate_pct decimal(5,2) [not null]
  indexes {
    (snapshot_date_key, ward_key) [pk]
  }
  note: 'Periodic snapshot fact table. Grain: One row per ward per day (end-of-day bed census).'
}

table fact_appointment {
  appointment_number varchar(20) [pk, not null]
  appointment_date_key int [not null]
  booking_date_key int [not null]
  appointment_time_key smallint [not null]
  patient_key int [not null]
  doctor_key int [not null]
  department_key smallint [not null]
  appointment_status_key smallint [not null]
  booking_channel_key smallint [not null]
  note: 'Factless fact table (event tracking). Grain: One row per booked outpatient appointment (with its final outcome).'
}

ref: fact_patient_visit.admission_date_key > dim_date.date_key
ref: fact_patient_visit.discharge_date_key > dim_date.date_key
ref: fact_patient_visit.patient_key > dim_patient.patient_key
ref: fact_patient_visit.doctor_key > dim_doctor.doctor_key
ref: fact_patient_visit.department_key > dim_department.department_key
ref: fact_patient_visit.diagnosis_key > dim_diagnosis.diagnosis_key
ref: fact_patient_visit.payer_key > dim_payer.payer_key
ref: fact_patient_visit.visit_profile_key > dim_visit_profile.visit_profile_key
ref: fact_bed_occupancy_daily.snapshot_date_key > dim_date.date_key
ref: fact_bed_occupancy_daily.ward_key > dim_ward.ward_key
ref: fact_bed_occupancy_daily.department_key > dim_department.department_key
ref: fact_appointment.appointment_date_key > dim_date.date_key
ref: fact_appointment.booking_date_key > dim_date.date_key
ref: fact_appointment.appointment_time_key > dim_time.time_key
ref: fact_appointment.patient_key > dim_patient.patient_key
ref: fact_appointment.doctor_key > dim_doctor.doctor_key
ref: fact_appointment.department_key > dim_department.department_key
ref: fact_appointment.appointment_status_key > dim_appointment_status.appointment_status_key
ref: fact_appointment.booking_channel_key > dim_booking_channel.booking_channel_key
```
