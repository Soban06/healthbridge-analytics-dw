"""Export synthetic source-system fixtures from the Phase 1 sample scenario."""

import csv
import sqlite3
from pathlib import Path

HERE = Path(__file__).resolve().parent
BUILD = HERE.parent / 'build'

MASTERS = {
    'patients': 'patient',
    'doctors': 'doctor',
    'departments': 'department',
    'wards': 'ward',
    'diagnoses': 'diagnosis',
    'payers': 'payer',
    'visit_profiles': 'visit_profile',
    'appointment_statuses': 'appointment_status',
    'booking_channels': 'booking_channel',
}

EVENTS = {
    'visits': '''
        select f.visit_number, a.full_date as admission_date, d.full_date as discharge_date,
               p.patient_mrn, dr.doctor_id, dep.department_code,
               case when f.diagnosis_key <> -1 then dx.icd10_code end as icd10_code,
               vp.visit_type, vp.admission_source, vp.discharge_status,
               f.wait_time_minutes, f.procedure_count, f.lab_test_count
        from fact_patient_visit f
        join dim_date a on a.date_key = f.admission_date_key
        join dim_date d on d.date_key = f.discharge_date_key
        join dim_patient p on p.patient_key = f.patient_key
        join dim_doctor dr on dr.doctor_key = f.doctor_key
        join dim_department dep on dep.department_key = f.department_key
        join dim_diagnosis dx on dx.diagnosis_key = f.diagnosis_key
        join dim_visit_profile vp on vp.visit_profile_key = f.visit_profile_key
        order by f.visit_number
    ''',
    'billing': '''
        select f.visit_number, p.payer_code, f.total_charge_amount,
               f.insurance_covered_amount, f.patient_paid_amount
        from fact_patient_visit f
        join dim_payer p on p.payer_key = f.payer_key
        order by f.visit_number
    ''',
    'bed_census': '''
        select d.full_date as snapshot_date, w.ward_code, dep.department_code,
               f.total_beds, f.occupied_beds, f.admissions_count, f.discharges_count
        from fact_bed_occupancy_daily f
        join dim_date d on d.date_key = f.snapshot_date_key
        join dim_ward w on w.ward_key = f.ward_key
        join dim_department dep on dep.department_key = f.department_key
        order by d.full_date, w.ward_code
    ''',
    'appointments': '''
        select f.appointment_number, a.full_date as appointment_date, b.full_date as booking_date,
               t.time_label as appointment_time, p.patient_mrn, dr.doctor_id,
               dep.department_code, s.status_code, ch.channel_code
        from fact_appointment f
        join dim_date a on a.date_key = f.appointment_date_key
        join dim_date b on b.date_key = f.booking_date_key
        join dim_time t on t.time_key = f.appointment_time_key
        join dim_patient p on p.patient_key = f.patient_key
        join dim_doctor dr on dr.doctor_key = f.doctor_key
        join dim_department dep on dep.department_key = f.department_key
        join dim_appointment_status s on s.appointment_status_key = f.appointment_status_key
        join dim_booking_channel ch on ch.booking_channel_key = f.booking_channel_key
        order by f.appointment_number
    ''',
}


def write_source(con, folder, name, sql):
    result = con.execute(sql)
    fields = [col[0] for col in result.description]
    rows = [dict(zip(fields, row)) for row in result]

    if name == 'patients':
        example = next(row for row in rows if row['patient_mrn'] == 'MRN-0004512')
        rows.append(dict(example, patient_mrn=' mrn-0004512 ', city=' LAHORE '))
    elif name == 'billing':
        example = next(row for row in rows if row['visit_number'] == 'VIS-2026-0004817')
        rows.append(dict(example, visit_number=' vis-2026-0004817 ', total_charge_amount=' 285,000.00 '))
    elif name == 'appointments':
        rows.append(dict(rows[0], appointment_number='APT-2026-DEMOERR', booking_date='invalid-date'))

    with (folder / f'{name}.csv').open('w', newline='', encoding='utf-8') as file:
        writer = csv.DictWriter(file, fieldnames=fields, lineterminator='\n')
        writer.writeheader()
        writer.writerows(rows)


def main():
    folder = HERE / 'sources'
    folder.mkdir(exist_ok=True)
    with sqlite3.connect(':memory:') as con:
        con.executescript((BUILD / 'schema.sql').read_text(encoding='utf-8'))
        con.executescript((BUILD / 'sample_data.sql').read_text(encoding='utf-8'))
        for source, name in MASTERS.items():
            table = f'dim_{name}'
            key, *fields = [r[1] for r in con.execute(f'pragma table_info({table})')]
            fields = [col for col in fields if col not in ('row_expiry_date', 'is_current')]
            write_source(con, folder, source, f'select {", ".join(fields)} from {table} where {key} <> -1 order by {key}')
        write_source(con, folder, 'calendar', '''
            select full_date, is_public_holiday from dim_date where date_key <> -1 order by full_date
        ''')
        for source, sql in EVENTS.items():
            write_source(con, folder, source, sql)
    print(f'Wrote {len(MASTERS) + len(EVENTS) + 1} synthetic CSVs to {folder}')


if __name__ == '__main__':
    main()
