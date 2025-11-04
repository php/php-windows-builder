function Set-FirebirdTestEnvironment {
    <#
    .SYNOPSIS
        Configure Firebird for PDO_Firebird tests on Windows.
    #>
    [CmdletBinding()]
    param ()
    process {
        $destDir = 'C:\Firebird'
        $firebirdVersion = 'v4.0.4'
        $firebirdRelease = "https://github.com/FirebirdSQL/firebird/releases/download/$firebirdVersion"
        New-Item -ItemType Directory -Force -Path $destDir | Out-Null

        $is64 = [Environment]::Is64BitOperatingSystem
        $url = if ($is64) {
            "$firebirdRelease/Firebird-4.0.4.3010-0-x64.zip"
        } else {
            "$firebirdRelease/Firebird-4.0.4.3010-0-Win32.zip"
        }

        $zipPath = Join-Path $destDir 'Firebird.zip'
        Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile $zipPath

        try {
            Expand-Archive -LiteralPath $zipPath -DestinationPath $destDir -Force
        } catch {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $destDir)
        }

        $env:PDO_FIREBIRD_TEST_DATABASE = 'C:\test.fdb'
        $env:PDO_FIREBIRD_TEST_DSN      = "firebird:dbname=127.0.0.1:$($env:PDO_FIREBIRD_TEST_DATABASE)"
        $env:PDO_FIREBIRD_TEST_USER     = 'SYSDBA'
        $env:PDO_FIREBIRD_TEST_PASS     = 'phpfi'

        $createUserSql = Join-Path $destDir 'create_user.sql'
        Set-Content -Path $createUserSql -Value "create user $($env:PDO_FIREBIRD_TEST_USER) password '$($env:PDO_FIREBIRD_TEST_PASS)';" -Encoding ASCII
        Add-Content -Path $createUserSql -Value 'commit;' -Encoding ASCII

        $setupSql = Join-Path $destDir 'setup.sql'
        Set-Content -Path $setupSql -Value "create database '$($env:PDO_FIREBIRD_TEST_DATABASE)' user '$($env:PDO_FIREBIRD_TEST_USER)' password '$($env:PDO_FIREBIRD_TEST_PASS)';" -Encoding ASCII
        if(-not(Test-Path pdo_firebird_db_created)) {
            & (Join-Path $destDir 'instsvc.exe') install -n TestInstance | Out-Null
            & (Join-Path $destDir 'isql') -q -i $setupSql | Out-Null
            & (Join-Path $destDir 'isql') -q -i $createUserSql -user sysdba $env:PDO_FIREBIRD_TEST_DATABASE | Out-Null
            & (Join-Path $destDir 'instsvc.exe') start -n TestInstance | Out-Null
            Set-Content -Path pdo_firebird_db_created -Value "db_created" -Encoding ASCII
        }

        Add-Path $destDir
    }
}
