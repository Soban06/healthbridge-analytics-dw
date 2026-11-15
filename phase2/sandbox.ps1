param(
    [ValidateSet('start', 'stop')]
    [string]$Action = 'start',
    [string]$PgBin = 'C:/Program Files/PostgreSQL/18/bin'
)

$ErrorActionPreference = 'Stop'
$sandbox = Join-Path $PSScriptRoot '.sandbox'
$data = Join-Path $sandbox 'data'
$passwordFile = Join-Path $sandbox 'pgpass.conf'
$pgCtl = Join-Path $PgBin 'pg_ctl.exe'

if ($Action -eq 'stop') {
    & $pgCtl -D $data -m fast -w stop
    exit $LASTEXITCODE
}

New-Item -ItemType Directory -Force -Path $sandbox | Out-Null
if (-not (Test-Path -LiteralPath (Join-Path $data 'PG_VERSION'))) {
    $password = [Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(18))
    $initialPassword = Join-Path $sandbox 'init-password.txt'
    Set-Content -LiteralPath $initialPassword -Value $password -Encoding ascii
    try {
        & (Join-Path $PgBin 'initdb.exe') -D $data -U dwbi -A scram-sha-256 --encoding=UTF8 --locale=C "--pwfile=$initialPassword"
        if ($LASTEXITCODE -ne 0) { throw 'Could not initialize the sandbox database cluster.' }
        Set-Content -LiteralPath $passwordFile -Value "127.0.0.1:55432:*:dwbi:$password" -Encoding ascii
    } finally {
        Remove-Item -LiteralPath $initialPassword -Force
    }
}

if (-not (Test-Path -LiteralPath $passwordFile)) { throw 'The local sandbox password file is missing.' }
$env:PGPASSFILE = $passwordFile
& $pgCtl -D $data status | Out-Null
if ($LASTEXITCODE -ne 0) {
    & $pgCtl -D $data -l (Join-Path $sandbox 'pg.log') -o '-h 127.0.0.1 -p 55432' -w -t 30 start
    if ($LASTEXITCODE -ne 0) { throw 'Could not start PostgreSQL. Check .sandbox/pg.log.' }
}

$connection = @('-w', '-h', '127.0.0.1', '-p', '55432', '-U', 'dwbi')
$psql = Join-Path $PgBin 'psql.exe'
$databaseExists = & $psql @connection -X -d postgres -Atc "select 1 from pg_database where datname = 'hospital_dw'"
if ($LASTEXITCODE -ne 0) { throw 'Could not connect to the sandbox database.' }
if ($databaseExists -ne '1') {
    & (Join-Path $PgBin 'createdb.exe') @connection hospital_dw
    if ($LASTEXITCODE -ne 0) { throw 'Could not create hospital_dw.' }
}
Write-Output 'PostgreSQL sandbox is ready at 127.0.0.1:55432, database hospital_dw.'
