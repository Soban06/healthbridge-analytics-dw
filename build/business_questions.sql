-- q1: What are the monthly trends in patient visits and revenue for each visit type (inpatient, outpatient, emergency, day care)?
select d.year_number, d.month_number, d.month_name, vp.visit_type,
       count(*)                   as total_visits,
       sum(f.total_charge_amount) as total_revenue
from fact_patient_visit f
join dim_date d           on f.discharge_date_key = d.date_key
join dim_visit_profile vp on f.visit_profile_key  = vp.visit_profile_key
group by d.year_number, d.month_number, d.month_name, vp.visit_type
order by d.year_number, d.month_number, vp.visit_type;

-- q2: What is the average length of stay (ALOS) of inpatients by diagnosis chapter and department?
select dg.icd10_chapter, dp.department_name,
       count(*)                                  as inpatient_visits,
       round(avg(1.0 * f.length_of_stay_days), 2) as avg_length_of_stay
from fact_patient_visit f
join dim_diagnosis dg     on f.diagnosis_key     = dg.diagnosis_key
join dim_department dp    on f.department_key    = dp.department_key
join dim_visit_profile vp on f.visit_profile_key = vp.visit_profile_key
where vp.visit_type = 'Inpatient'
group by dg.icd10_chapter, dp.department_name
order by avg_length_of_stay desc;

-- q3: What is the 30-day readmission rate by department and diagnosis block?
select dp.department_name, dg.diagnosis_block,
       count(*)                    as inpatient_visits,
       sum(f.readmission_30d_flag) as readmissions,
       round(100.0 * sum(f.readmission_30d_flag) / count(*), 2) as readmission_rate_pct
from fact_patient_visit f
join dim_department dp    on f.department_key    = dp.department_key
join dim_diagnosis dg     on f.diagnosis_key     = dg.diagnosis_key
join dim_visit_profile vp on f.visit_profile_key = vp.visit_profile_key
where vp.visit_type = 'Inpatient'
group by dp.department_name, dg.diagnosis_block
order by readmission_rate_pct desc;

-- q4: What are the five most common diagnoses for each age band and gender?
select age_band, gender, diagnosis_description, visit_count, rnk
from (
    select x.age_band, x.gender, x.diagnosis_description,
           count(*) as visit_count,
           rank() over (partition by x.age_band, x.gender
                        order by count(*) desc) as rnk
    from (
        select case when f.age_at_visit_years is null then 'Unknown'
                    when f.age_at_visit_years < 13 then '00-12'
                    when f.age_at_visit_years < 20 then '13-19'
                    when f.age_at_visit_years < 40 then '20-39'
                    when f.age_at_visit_years < 60 then '40-59'
                    else '60+' end as age_band,
               p.gender, dg.diagnosis_description
        from fact_patient_visit f
        join dim_patient p    on f.patient_key   = p.patient_key
        join dim_diagnosis dg on f.diagnosis_key = dg.diagnosis_key
    ) x
    group by x.age_band, x.gender, x.diagnosis_description
) r
where r.rnk <= 5
order by age_band, gender, rnk;

-- q5: How is revenue split across payer types and payers, and which payers have the highest outstanding balances?
select py.payer_type, py.payer_name,
       count(*)                        as visits,
       sum(f.total_charge_amount)      as total_billed,
       sum(f.insurance_covered_amount) as payer_covered,
       sum(f.patient_paid_amount)      as patient_paid,
       sum(f.outstanding_amount)       as outstanding,
       round(100.0 * sum(f.outstanding_amount)
             / nullif(sum(f.total_charge_amount), 0), 2) as outstanding_pct
from fact_patient_visit f
join dim_payer py on f.payer_key = py.payer_key
group by py.payer_type, py.payer_name
order by outstanding desc;

-- q6: Which doctors handle the highest patient volume and revenue within each specialization?
select doc.specialization, doc.doctor_id, doc.doctor_full_name,
       count(*)                   as visits,
       sum(f.total_charge_amount) as revenue,
       rank() over (partition by doc.specialization
                    order by count(*) desc) as volume_rank
from fact_patient_visit f
join dim_doctor doc on f.doctor_key = doc.doctor_key
group by doc.specialization, doc.doctor_id, doc.doctor_full_name
order by doc.specialization, volume_rank;

-- q7: Which cities and provinces do our patients come from (catchment area), and how much revenue does each generate?
select p.province, p.city,
       count(distinct p.patient_mrn) as unique_patients,
       count(*)                      as visits,
       sum(f.total_charge_amount)    as revenue
from fact_patient_visit f
join dim_patient p on f.patient_key = p.patient_key
group by p.province, p.city
order by visits desc;

-- q8: What is the average bed occupancy rate of each ward and ward type, and on how many days did each ward exceed 90% occupancy?
select w.ward_type, w.ward_name,
       round(100.0 * sum(f.occupied_beds) / nullif(sum(f.total_beds), 0), 2) as avg_occupancy_pct,
       sum(case when f.occupancy_rate_pct > 90 then 1 else 0 end)             as days_above_90_pct
from fact_bed_occupancy_daily f
join dim_ward w on f.ward_key          = w.ward_key
join dim_date d on f.snapshot_date_key = d.date_key
where d.year_number = 2026
group by w.ward_type, w.ward_name
order by avg_occupancy_pct desc;

-- q9: What are the appointment no-show and cancellation rates by department and booking channel?
select dp.department_name, bc.channel_name,
       count(*) as total_appointments,
       sum(case when s.status_code = 'NOSHOW' then 1 else 0 end) as no_shows,
       round(100.0 * sum(case when s.status_code = 'NOSHOW' then 1 else 0 end)
             / nullif(sum(case when s.status_code in ('COMPLETED', 'NOSHOW')
                               then 1 else 0 end), 0), 2) as no_show_rate_pct,
       round(100.0 * sum(case when s.status_category = 'Cancelled' then 1 else 0 end)
             / count(*), 2) as cancellation_rate_pct
from fact_appointment f
join dim_department dp          on f.department_key         = dp.department_key
join dim_booking_channel bc     on f.booking_channel_key    = bc.booking_channel_key
join dim_appointment_status s   on f.appointment_status_key = s.appointment_status_key
group by dp.department_name, bc.channel_name
order by no_show_rate_pct desc;

-- q10: Which days of the week and hours of the day have the highest outpatient appointment demand?
select d.day_of_week, d.day_name, t.hour_24, t.hour_label,
       count(*) as appointments
from fact_appointment f
join dim_date d on f.appointment_date_key = d.date_key
join dim_time t on f.appointment_time_key = t.time_key
group by d.day_of_week, d.day_name, t.hour_24, t.hour_label
order by appointments desc;
