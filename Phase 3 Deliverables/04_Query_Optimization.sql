-- Phase 3 query optimization: EXPLAIN ANALYZE before and after adding indexes.
-- The Phase 2 schema already indexes every fact foreign key, so these indexes target
-- filters and sort orders that the existing indexes do not cover.
-- Safe to re-run: each index is dropped first so the "before" plan is measured without it.

set search_path to project_dw, pg_catalog;

drop index if exists ix_fact_patient_visit_outstanding_amount;
drop index if exists ix_fact_bed_occupancy_daily_occupancy_rate_pct;
analyze fact_patient_visit;
analyze fact_bed_occupancy_daily;

-- t1: Ten largest unpaid visit balances (collections follow-up list).
-- before
explain analyze
select visit_number, patient_key, outstanding_amount
from fact_patient_visit
where outstanding_amount > 0
order by outstanding_amount desc
limit 10;

create index ix_fact_patient_visit_outstanding_amount
    on fact_patient_visit (outstanding_amount desc);
analyze fact_patient_visit;

-- after
explain analyze
select visit_number, patient_key, outstanding_amount
from fact_patient_visit
where outstanding_amount > 0
order by outstanding_amount desc
limit 10;

-- t2: Ward-days at or above 99% occupancy (bed capacity alerts).
-- before
explain analyze
select snapshot_date_key, ward_key, occupancy_rate_pct
from fact_bed_occupancy_daily
where occupancy_rate_pct >= 99;

create index ix_fact_bed_occupancy_daily_occupancy_rate_pct
    on fact_bed_occupancy_daily (occupancy_rate_pct);
analyze fact_bed_occupancy_daily;

-- after
explain analyze
select snapshot_date_key, ward_key, occupancy_rate_pct
from fact_bed_occupancy_daily
where occupancy_rate_pct >= 99;
