-- Phase 3 analytical SQL: aggregations (SUM, AVG, COUNT) over the hospital warehouse.
-- Revenue is the billed charge of completed visits (fact_patient_visit.total_charge_amount, PKR).
-- Visits are dated by discharge, as in the Phase 1 business questions.

set search_path to project_dw, pg_catalog;

-- a1: Headline KPIs for the whole snapshot.
select count(*)                                  as total_visits,
       count(distinct p.patient_mrn)             as unique_patients,
       sum(f.total_charge_amount)                as total_revenue,
       round(avg(f.total_charge_amount), 2)      as avg_revenue_per_visit,
       sum(f.insurance_covered_amount + f.patient_paid_amount) as collected_amount,
       sum(f.outstanding_amount)                 as outstanding_amount
from fact_patient_visit f
join dim_patient p on f.patient_key = p.patient_key;

-- a2: Monthly revenue with month-over-month growth and a running total.
select year_month, month_name, visits, revenue,
       round(100.0 * (revenue - lag(revenue) over (order by year_month))
             / nullif(lag(revenue) over (order by year_month), 0), 2) as revenue_growth_pct,
       sum(revenue) over (order by year_month)                        as cumulative_revenue
from (
    select d.year_month, d.month_name,
           count(*)                   as visits,
           sum(f.total_charge_amount) as revenue
    from fact_patient_visit f
    join dim_date d on f.discharge_date_key = d.date_key
    group by d.year_month, d.month_name
) monthly
order by year_month;

-- a3: Visits, revenue and average bill by visit type, with each type's share of revenue.
select vp.visit_type,
       count(*)                             as visits,
       sum(f.total_charge_amount)           as revenue,
       round(avg(f.total_charge_amount), 2) as avg_revenue_per_visit,
       round(100.0 * sum(f.total_charge_amount)
             / sum(sum(f.total_charge_amount)) over (), 2) as revenue_share_pct
from fact_patient_visit f
join dim_visit_profile vp on f.visit_profile_key = vp.visit_profile_key
group by vp.visit_type
order by revenue desc;

-- a4: Department (service line) performance ranked by revenue.
select dp.department_category, dp.department_name,
       count(*)                             as visits,
       count(distinct p.patient_mrn)        as unique_patients,
       sum(f.total_charge_amount)           as revenue,
       round(avg(f.total_charge_amount), 2) as avg_revenue_per_visit,
       rank() over (order by sum(f.total_charge_amount) desc) as revenue_rank
from fact_patient_visit f
join dim_department dp on f.department_key = dp.department_key
join dim_patient p     on f.patient_key    = p.patient_key
group by dp.department_category, dp.department_name
order by revenue_rank;

-- a5: Billing and collection position by payer type.
select py.payer_type,
       count(*)                        as visits,
       sum(f.total_charge_amount)      as billed,
       sum(f.insurance_covered_amount) as payer_covered,
       sum(f.patient_paid_amount)      as patient_paid,
       sum(f.outstanding_amount)       as outstanding,
       round(100.0 * sum(f.outstanding_amount) / nullif(sum(f.total_charge_amount), 0), 2) as outstanding_pct,
       round(100.0 * sum(f.outstanding_amount) / sum(sum(f.outstanding_amount)) over (), 2) as share_of_all_outstanding_pct
from fact_patient_visit f
join dim_payer py on f.payer_key = py.payer_key
group by py.payer_type
order by outstanding desc;

-- a6: Monthly outpatient appointment outcomes.
select d.year_month,
       count(*) as booked_appointments,
       sum(case when s.status_code = 'COMPLETED' then 1 else 0 end) as completed,
       sum(case when s.status_code = 'NOSHOW' then 1 else 0 end)    as no_shows,
       round(100.0 * sum(case when s.status_code = 'NOSHOW' then 1 else 0 end)
             / nullif(sum(case when s.status_code in ('COMPLETED', 'NOSHOW') then 1 else 0 end), 0), 2) as no_show_rate_pct
from fact_appointment f
join dim_date d               on f.appointment_date_key   = d.date_key
join dim_appointment_status s on f.appointment_status_key = s.appointment_status_key
group by d.year_month
order by d.year_month;

-- a7: Average daily bed occupancy by ward type and month.
select w.ward_type, d.year_month,
       count(*)                                 as ward_days,
       round(avg(f.occupied_beds), 2)           as avg_occupied_beds,
       round(100.0 * sum(f.occupied_beds) / nullif(sum(f.total_beds), 0), 2) as avg_occupancy_pct
from fact_bed_occupancy_daily f
join dim_ward w on f.ward_key          = w.ward_key
join dim_date d on f.snapshot_date_key = d.date_key
group by w.ward_type, d.year_month
order by w.ward_type, d.year_month;
