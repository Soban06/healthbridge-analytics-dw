-- Phase 3 reporting views for Power BI, created in project_reporting.
-- Run after the Phase 2 load: psql -f "Phase 3 Deliverables/03_Reporting_Views.sql"

-- One row per discharge month: visits, patients, revenue, collections and revenue growth.
create or replace view project_reporting.vw_monthly_sales as
select year_number, month_number, month_name, year_month,
       visits, unique_patients, revenue, payer_covered, patient_paid, outstanding,
       avg_revenue_per_visit,
       round(100.0 * (revenue - lag(revenue) over (order by year_month))
             / nullif(lag(revenue) over (order by year_month), 0), 2) as revenue_growth_pct
from (
    select d.year_number, d.month_number, d.month_name, d.year_month,
           count(*)                             as visits,
           count(distinct p.patient_mrn)        as unique_patients,
           sum(f.total_charge_amount)           as revenue,
           sum(f.insurance_covered_amount)      as payer_covered,
           sum(f.patient_paid_amount)           as patient_paid,
           sum(f.outstanding_amount)            as outstanding,
           round(avg(f.total_charge_amount), 2) as avg_revenue_per_visit
    from project_dw.fact_patient_visit f
    join project_dw.dim_date d    on f.discharge_date_key = d.date_key
    join project_dw.dim_patient p on f.patient_key        = p.patient_key
    group by d.year_number, d.month_number, d.month_name, d.year_month
) monthly;

-- One row per patient (MRN) with visits: current profile, activity, spend and value segment.
-- Segments split patients into thirds by total revenue (High, Medium, Low value).
create or replace view project_reporting.vw_customer_analysis as
with activity as (
    select p.patient_mrn,
           count(*)                             as visits,
           sum(f.total_charge_amount)           as revenue,
           round(avg(f.total_charge_amount), 2) as avg_revenue_per_visit,
           sum(f.outstanding_amount)            as outstanding,
           min(a.full_date)                     as first_admission_date,
           max(d.full_date)                     as last_discharge_date
    from project_dw.fact_patient_visit f
    join project_dw.dim_patient p on f.patient_key        = p.patient_key
    join project_dw.dim_date a    on f.admission_date_key = a.date_key
    join project_dw.dim_date d    on f.discharge_date_key = d.date_key
    group by p.patient_mrn
)
select c.patient_mrn, c.patient_full_name, c.gender, c.city, c.province,
       x.visits, x.revenue, x.avg_revenue_per_visit, x.outstanding,
       x.first_admission_date, x.last_discharge_date,
       case ntile(3) over (order by x.revenue desc, x.patient_mrn)
            when 1 then 'High value'
            when 2 then 'Medium value'
            else 'Low value'
       end as customer_segment
from activity x
join project_dw.dim_patient c on c.patient_mrn = x.patient_mrn and c.is_current = 1;

-- One row per department (service line) with visits: volume, revenue and clinical measures.
create or replace view project_reporting.vw_product_performance as
select dp.department_category, dp.department_name,
       count(*)                             as visits,
       count(distinct p.patient_mrn)        as unique_patients,
       sum(f.total_charge_amount)           as revenue,
       round(avg(f.total_charge_amount), 2) as avg_revenue_per_visit,
       sum(f.outstanding_amount)            as outstanding,
       round(avg(f.length_of_stay_days) filter (where vp.visit_type = 'Inpatient'), 2) as avg_inpatient_stay_days,
       round(100.0 * sum(f.total_charge_amount) / sum(sum(f.total_charge_amount)) over (), 2) as revenue_share_pct,
       rank() over (order by sum(f.total_charge_amount) desc) as revenue_rank
from project_dw.fact_patient_visit f
join project_dw.dim_department dp    on f.department_key    = dp.department_key
join project_dw.dim_patient p        on f.patient_key       = p.patient_key
join project_dw.dim_visit_profile vp on f.visit_profile_key = vp.visit_profile_key
group by dp.department_category, dp.department_name;
