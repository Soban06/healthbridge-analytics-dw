-- Phase 3 OLAP queries: ROLLUP and CUBE over the hospital warehouse.
-- Region is the patient's province (patient version at admission or appointment date).

set search_path to project_dw, pg_catalog;

-- o1: ROLLUP of visit revenue along Region -> Category -> Product
--     (province -> department category -> department).
--     Returns department revenue, category totals, region totals and the grand total.
select case grouping(p.province, dp.department_category, dp.department_name)
            when 0 then 'Product revenue'
            when 1 then 'Category total'
            when 3 then 'Region total'
            else 'Grand total'
       end                                                   as level,
       coalesce(p.province, 'All regions')                   as region,
       coalesce(dp.department_category, 'All categories')    as category,
       coalesce(dp.department_name, 'All departments')       as product,
       count(*)                                              as visits,
       sum(f.total_charge_amount)                            as revenue
from fact_patient_visit f
join dim_patient p     on f.patient_key    = p.patient_key
join dim_department dp on f.department_key = dp.department_key
group by rollup (p.province, dp.department_category, dp.department_name)
order by grouping(p.province), p.province,
         grouping(dp.department_category), dp.department_category,
         grouping(dp.department_name), dp.department_name;

-- o2: CUBE of outpatient appointments across Region x Channel
--     (province x booking channel). Returns every combination, each region total,
--     each channel total and the grand total.
select case grouping(p.province, bc.channel_name)
            when 0 then 'Region and channel'
            when 1 then 'Region total'
            when 2 then 'Channel total'
            else 'Grand total'
       end                                          as level,
       coalesce(p.province, 'All regions')          as region,
       coalesce(bc.channel_name, 'All channels')    as channel,
       count(*)                                     as booked_appointments,
       sum(case when s.status_code = 'COMPLETED' then 1 else 0 end) as completed,
       sum(case when s.status_code = 'NOSHOW' then 1 else 0 end)    as no_shows
from fact_appointment f
join dim_patient p              on f.patient_key            = p.patient_key
join dim_booking_channel bc     on f.booking_channel_key    = bc.booking_channel_key
join dim_appointment_status s   on f.appointment_status_key = s.appointment_status_key
group by cube (p.province, bc.channel_name)
order by grouping(p.province), p.province, grouping(bc.channel_name), bc.channel_name;
