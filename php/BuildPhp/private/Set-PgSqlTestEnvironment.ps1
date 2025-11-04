function Set-PgSqlTestEnvironment {
    <#
    .SYNOPSIS
        Configure environment variables for PostgreSQL-related PHP tests and ensure the test database exists.
    #>
    [CmdletBinding()]
    param ()
    process {
        $env:PGUSER = 'postgres'
        $env:PGPASSWORD = 'Password12!'
        if(-not(Test-Path pgsql_init)) {
            Set-Service -Name "postgresql-x64-14" -StartupType manual -Status Running -WarningAction SilentlyContinue
            Set-Content -Path pgsql_init -Value "initialized" -Encoding ASCII
        }
        $prevPgPwd = $env:PGPASSWORD
        $env:PGPASSWORD = 'root'
        if(-not(Test-Path pgsql_db_created)) {
            & "$env:PGBIN\psql" -U postgres -c "ALTER USER $($env:PGUSER) WITH PASSWORD '$($prevPgPwd)';"
            Set-Content -Path pgsql_db_created -Value "db_created" -Encoding ASCII
        }
        $env:PGPASSWORD = $prevPgPwd
        $env:PDO_PGSQL_TEST_DSN = "pgsql:host=127.0.0.1 port=5432 dbname=test user=$($env:PGUSER) password=$($env:PGPASSWORD)"
        if ($env:PGBIN) {
            $env:TMP_POSTGRESQL_BIN = $env:PGBIN
        }

        $testsRoot = Join-Path (Get-Location).Path 'tests'
        $configDir = Join-Path $testsRoot 'ext/pgsql/tests'
        $configFile = Join-Path $configDir 'config.inc'
        New-Item -ItemType Directory -Force -Path $configDir

        $phpLine = "<?php $`conn_str = 'host=127.0.0.1 dbname=test port=5432 user=$($env:PGUSER) password=$($env:PGPASSWORD)'; ?>"
        Add-Content -Path $configFile -Value $phpLine -Encoding ASCII

        $createdb = Join-Path $env:TMP_POSTGRESQL_BIN 'createdb.exe'
        if (-not (Test-Path $createdb)) {
            throw "createdb.exe not found. Ensure PGBIN is set to PostgreSQL bin directory."
        }
        if(-not(Test-Path pgsql_test_db_created)) {
            & $createdb 'test'
            Set-Content -Path pgsql_test_db_created -Value "test_db_created" -Encoding ASCII
        }
    }
}
