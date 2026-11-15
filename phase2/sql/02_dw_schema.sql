create schema if not exists project_dw;
create schema if not exists project_reporting;

set local search_path to project_dw, pg_catalog;
select to_regclass('project_dw.dim_date') is null as install_warehouse \gset
\if :install_warehouse
\ir ../../build/schema.sql
\endif

create table if not exists project_reporting.data_quality (
    check_name text primary key,
    actual numeric not null,
    expected numeric not null,
    passed boolean generated always as (actual = expected) stored
);
