with inpatient_history as (
    select visit_number, admission_date - lag(discharge_date) over (
        partition by patient_mrn order by admission_date, visit_number
    ) as days_since_discharge
    from project_staging.stg_visits where visit_type = 'Inpatient'
)
insert into fact_patient_visit (
    visit_number, admission_date_key, discharge_date_key, patient_key, doctor_key,
    department_key, diagnosis_key, payer_key, visit_profile_key, age_at_visit_years,
    length_of_stay_days, wait_time_minutes, procedure_count, lab_test_count,
    total_charge_amount, insurance_covered_amount, patient_paid_amount, outstanding_amount, readmission_30d_flag
)
select v.visit_number, a.date_key, d.date_key, p.patient_key, dr.doctor_key,
       dep.department_key, coalesce(dx.diagnosis_key, -1), py.payer_key, vp.visit_profile_key,
       extract(year from age(v.admission_date, p.date_of_birth)), v.discharge_date - v.admission_date,
       v.wait_time_minutes, v.procedure_count, v.lab_test_count, b.total_charge_amount,
       b.insurance_covered_amount, b.patient_paid_amount,
       b.total_charge_amount - b.insurance_covered_amount - b.patient_paid_amount,
       case when h.days_since_discharge between 0 and 30 then 1 else 0 end
from project_staging.stg_visits v
join project_staging.stg_billing b using (visit_number)
join dim_date a on a.full_date = v.admission_date
join dim_date d on d.full_date = v.discharge_date
join dim_patient p on p.patient_mrn = v.patient_mrn and v.admission_date between p.row_effective_date and p.row_expiry_date
join dim_doctor dr on dr.doctor_id = v.doctor_id and v.discharge_date between dr.row_effective_date and dr.row_expiry_date
join dim_department dep on dep.department_code = v.department_code
left join dim_diagnosis dx on dx.icd10_code = v.icd10_code
join dim_payer py on py.payer_code = b.payer_code
join dim_visit_profile vp on (vp.visit_type, vp.admission_source, vp.discharge_status) = (v.visit_type, v.admission_source, v.discharge_status)
left join inpatient_history h on h.visit_number = v.visit_number;

insert into fact_bed_occupancy_daily (
    snapshot_date_key, ward_key, department_key, total_beds, occupied_beds, available_beds,
    admissions_count, discharges_count, occupancy_rate_pct
)
select d.date_key, w.ward_key, dep.department_key, c.total_beds, c.occupied_beds,
       c.total_beds - c.occupied_beds, c.admissions_count, c.discharges_count,
       coalesce(round(100.0 * c.occupied_beds / nullif(c.total_beds, 0), 2), 0)
from project_staging.stg_bed_census c
join dim_date d on d.full_date = c.snapshot_date
join dim_ward w on w.ward_code = c.ward_code
join dim_department dep on dep.department_code = c.department_code;

insert into fact_appointment (
    appointment_number, appointment_date_key, booking_date_key, appointment_time_key, patient_key,
    doctor_key, department_key, appointment_status_key, booking_channel_key
)
select s.appointment_number, a.date_key, b.date_key, t.time_key, p.patient_key, dr.doctor_key,
       dep.department_key, st.appointment_status_key, ch.booking_channel_key
from project_staging.stg_appointments s
join dim_date a on a.full_date = s.appointment_date
join dim_date b on b.full_date = s.booking_date
join dim_time t on t.time_label = to_char(s.appointment_time, 'HH24:MI')
join dim_patient p on p.patient_mrn = s.patient_mrn and s.appointment_date between p.row_effective_date and p.row_expiry_date
join dim_doctor dr on dr.doctor_id = s.doctor_id and s.appointment_date between dr.row_effective_date and dr.row_expiry_date
join dim_department dep on dep.department_code = s.department_code
join dim_appointment_status st on st.status_code = s.status_code
join dim_booking_channel ch on ch.channel_code = s.channel_code;
