Function Add-OciDB {
    <#
    .SYNOPSIS
        Add OCI DB.
    #>
    [OutputType()]
    param(
    )
    begin {
        $installDir = 'C:\oracle\product\21c'
        $setupDir = 'C:\tools\oracle-setup'
        $workingDir = 'C:\tools\oracle'

        $dbPassword = 'oracle'
        $dbPort = '1521'
        $dbEmExpressPort = '5550'
        $dbCharset = 'AL32UTF8'
        $dbDomain = 'localdomain'

        $dbZipFile = 'OracleXE213_Win64.zip'
        $dbUrl = 'https://download.oracle.com/otn-pub/otn_software/db-express/OracleXE213_Win64.zip'
    }
    process {
        Add-Type -Assembly "System.IO.Compression.Filesystem"
        @(
            $workingDir,
            $setupDir,
            "$setupDir\temp",
            $installDir
        ) | ForEach-Object {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
        }

        Get-File -Url $dbUrl -OutFile $dbZipFile
        $rspContent = @(
            "INSTALLDIR=$installDir\"
            "PASSWORD=$dbPassword"
            "LISTENER_PORT=$dbPort"
            "EMEXPRESS_PORT=$dbEmExpressPort"
            "CHAR_SET=$dbCharset"
            "DB_DOMAIN=$dbDomain"
        )
        $argumentList = @(
            '/s'
            "/v`"RSP_FILE=$setupDir\OracleServerInstall.rsp`""
            "/v`"/L*v $setupDir\OracleServerSetup.log`""
            '/v"/qn"'
        )
        if (Get-Command 7z -ErrorAction SilentlyContinue) {
            7z x $dbZipFile "-o$setupDir" -y | Out-Null
        } else {
            [System.IO.Compression.ZipFile]::ExtractToDirectory($dbZipFile, $setupDir)
        }
        $rspContent | Set-Content -Path $setupDir\OracleServerInstall.rsp

        $oldEnv = @{
            TMPDIR = $env:TMPDIR
            TMP    = $env:TMP
            TEMP   = $env:TEMP
        }

        try {
            $env:TMPDIR = "$setupDir\temp"
            $env:TMP    = "$setupDir\temp"
            $env:TEMP   = "$setupDir\temp"

            Start-Process -FilePath $setupDir\setup.exe -ArgumentList $argumentList -WorkingDirectory $workingDir -NoNewWindow -Wait
        }
        finally {
            $env:TMPDIR = $oldEnv.TMPDIR
            $env:TMP    = $oldEnv.TMP
            $env:TEMP   = $oldEnv.TEMP
        }

        Add-Path -PathItem "$oracleHome\bin"
        $env:ORACLE_HOME="$installDir\dbhomeXE"
    }
    end {
    }
}