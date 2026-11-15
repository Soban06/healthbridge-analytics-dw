"""Clean the synthetic CSVs and load one complete PostgreSQL snapshot."""

import csv
import io
import json
import os
import re
import subprocess
from datetime import date, time
from decimal import Decimal, InvalidOperation
from pathlib import Path

HERE = Path(__file__).resolve().parent
SOURCES = {
    'patients': ('patient_mrn', 'row_effective_date'),
    'doctors': ('doctor_id', 'row_effective_date'),
    'departments': ('department_code',),
    'wards': ('ward_code',),
    'diagnoses': ('icd10_code',),
    'payers': ('payer_code',),
    'visit_profiles': ('visit_type', 'admission_source', 'discharge_status'),
    'appointment_statuses': ('status_code',),
    'booking_channels': ('channel_code',),
    'calendar': ('full_date',),
    'visits': ('visit_number',),
    'billing': ('visit_number',),
    'bed_census': ('snapshot_date', 'ward_code'),
    'appointments': ('appointment_number',),
}
FLAGS = {
    'has_inpatient_beds', 'is_isolation_ward', 'is_chronic', 'is_communicable',
    'is_attended', 'is_public_holiday',
}
INTEGERS = FLAGS | {
    'floor_number', 'wait_time_minutes', 'procedure_count', 'lab_test_count',
    'total_beds', 'occupied_beds', 'admissions_count', 'discharges_count',
}
MONEY = ('total_charge_amount', 'insurance_covered_amount', 'patient_paid_amount')
OPTIONAL = {'date_of_birth'}


def clean_value(source, column, raw):
    value = ' '.join(raw.split())
    if not value:
        if column in OPTIONAL or (source == 'visits' and column == 'icd10_code'):
            return None
        raise ValueError(f'{column} is required')
    try:
        if column in INTEGERS:
            number = int(value)
            if not -32768 <= number <= 32767 or (column != 'floor_number' and number < 0):
                raise ValueError
            if column in FLAGS and number not in (0, 1):
                raise ValueError
            return number
        if column in MONEY or column == 'default_coverage_pct':
            number = Decimal(value.replace(',', ''))
            upper = Decimal('100') if column == 'default_coverage_pct' else Decimal('9999999999.99')
            if not number.is_finite() or not 0 <= number <= upper or number != round(number, 2):
                raise ValueError
            return format(number, '.2f')
        if column.endswith('_date') or column == 'date_of_birth':
            return date.fromisoformat(value).isoformat()
        if column == 'appointment_time':
            slot = time.fromisoformat(value)
            if slot.tzinfo or slot.minute % 15 or slot.second or slot.microsecond:
                raise ValueError
            return slot.isoformat(timespec='minutes')
    except (InvalidOperation, ValueError) as error:
        raise ValueError(f'{column} has an invalid value: {value}') from error

    if column.endswith(('_code', '_number')) or column in ('patient_mrn', 'doctor_id'):
        return value.upper()
    if column in ('city', 'province', 'country'):
        return value.title()
    return value


def validate_row(source, row):
    if source == 'visits':
        admission, discharge = row['admission_date'], row['discharge_date']
        if discharge < admission or (row['visit_type'] != 'Inpatient' and discharge != admission):
            raise ValueError('invalid visit dates for the visit type')
    elif source == 'billing':
        total, covered, paid = (Decimal(row[col]) for col in MONEY)
        if covered + paid > total:
            raise ValueError('covered and paid amounts exceed total charge')
    elif source == 'bed_census' and not 0 <= row['occupied_beds'] <= row['total_beds']:
        raise ValueError('occupied beds exceed total beds')
    elif source == 'appointments' and row['booking_date'] > row['appointment_date']:
        raise ValueError('booking date follows appointment date')
    elif source == 'patients':
        if row['registration_date'] > row['row_effective_date']:
            raise ValueError('patient version predates registration')
        if row['date_of_birth'] and row['date_of_birth'] > row['registration_date']:
            raise ValueError('birth date follows registration')
    elif source == 'doctors' and row['joining_date'] > row['row_effective_date']:
        raise ValueError('doctor version predates joining')


def write_copy(script, table, columns, rows):
    script.write(f'\\copy project_staging.{table} ({", ".join(columns)}) from stdin with (format csv)\n')
    csv.writer(script, lineterminator='\n').writerows(rows)
    script.write('\\.\n')


def stage_sources(script):
    raw_rows, issues, summaries = [], [], []
    tables = [f'project_staging.stg_{name}' for name in SOURCES]
    script.write('truncate project_staging.cleaning_issue, project_staging.raw_source, '
                 'project_staging.load_summary, ' + ', '.join(tables) + ';\n')

    for source, key_columns in SOURCES.items():
        seen = {}
        duplicates = rejected = input_rows = 0
        with (HERE / 'sources' / f'{source}.csv').open(newline='', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            columns = reader.fieldnames
            if not columns or len(columns) != len(set(columns)) or not set(key_columns).issubset(columns):
                raise ValueError(f'{source}.csv has an invalid header')
            if any(not re.fullmatch('[a-z_][a-z0-9_]*', col) for col in columns):
                raise ValueError(f'{source}.csv has an invalid column name')
            for offset, raw in enumerate(reader, start=2):
                input_rows += 1
                raw_rows.append((source, offset, json.dumps(raw, ensure_ascii=False)))
                try:
                    if None in raw or any(raw[col] is None for col in columns):
                        raise ValueError('incorrect number of fields')
                    row = {col: clean_value(source, col, raw[col]) for col in columns}
                    validate_row(source, row)
                    key = tuple(row[col] for col in key_columns)
                    if key in seen:
                        if seen[key] != row:
                            raise ValueError('conflicting values for an existing business key')
                        duplicates += 1
                        issues.append((source, offset, 'duplicate', 'same business key and values after cleaning'))
                    else:
                        seen[key] = row
                except ValueError as error:
                    rejected += 1
                    reason = ' '.join(str(error).split())
                    issues.append((source, offset, 'rejected', reason))
        write_copy(script, f'stg_{source}', columns, ([row[col] for col in columns] for row in seen.values()))
        summaries.append((source, input_rows, len(seen), duplicates, rejected))

    write_copy(script, 'raw_source', ('source_name', 'source_row', 'payload'), raw_rows)
    write_copy(script, 'cleaning_issue', ('source_name', 'source_row', 'disposition', 'reason'), issues)
    write_copy(script, 'load_summary', ('source_name', 'input_rows', 'clean_rows', 'duplicates', 'rejected'), summaries)


def main():
    queries = (HERE.parent / 'build' / 'business_questions.sql').read_text(encoding='utf-8')
    blocks = re.split(r'^-- (q\d+):[^\n]*\n', queries, flags=re.MULTILINE)[1:]
    if blocks[::2] != [f'q{i}' for i in range(1, 11)]:
        raise ValueError('Expected q1 through q10 in business_questions.sql')

    script = io.StringIO()
    script.write('begin;\nselect pg_advisory_xact_lock(2411, 2026);\n')
    script.write('\\i sql/01_staging_schema.sql\n\\i sql/02_dw_schema.sql\n')
    stage_sources(script)
    script.write('\\i sql/03_load_dimensions.sql\n\\i sql/04_load_facts.sql\n')
    for name, query in zip(blocks[::2], blocks[1::2]):
        script.write(f'create or replace view project_reporting.{name} as\n{query.strip()}\n')
    script.write('\\i sql/05_data_quality.sql\ncommit;\n')
    script.write('table project_staging.load_summary;\ntable project_reporting.data_quality;\n')

    env = os.environ.copy()
    env.setdefault('PGHOST', '127.0.0.1')
    env.setdefault('PGPORT', '55432')
    env.setdefault('PGUSER', 'dwbi')
    env.setdefault('PGDATABASE', 'hospital_dw')
    env.setdefault('PGCLIENTENCODING', 'UTF8')
    password_file = HERE / '.sandbox' / 'pgpass.conf'
    if password_file.is_file():
        env.setdefault('PGPASSFILE', str(password_file))

    subprocess.run([env.get('DWBI_PSQL', 'psql'), '-X', '-w', '-q', '-v', 'ON_ERROR_STOP=1', '-P', 'pager=off'],
                   input=script.getvalue().encode('utf-8'), cwd=HERE, env=env, check=True)


if __name__ == '__main__':
    main()
