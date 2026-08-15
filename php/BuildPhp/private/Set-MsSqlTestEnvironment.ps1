function Set-MsSqlTestEnvironment {
    <#
    .SYNOPSIS
        Install Microsoft SQL Server Express required for SQL Server-related tests.
    #>
    [CmdletBinding()]
    param ()
    process {
        if(Test-Path mssql_init) {
            return
        }

        $serviceName = 'MSSQL$SQLEXPRESS'
        $installExitCode = $null
        $service = $null
        for($attempt = 1; $attempt -le 3; $attempt++) {
            Write-Host "Installing SQL Server Express (attempt $attempt of 3)..."
            & choco install sql-server-express -y --no-progress --install-arguments="/SECURITYMODE=SQL /SAPWD=Password12!"
            $installExitCode = $LASTEXITCODE
            $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
            if ($service) {
                break
            }

            if ($attempt -lt 3) {
                Write-Warning "SQL Server Express installation did not create service $serviceName (choco exit code: $installExitCode). Retrying..."
                Start-Sleep -Seconds (15 * $attempt)
            }
        }

        if (-not $service) {
            throw "Failed to install SQL Server Express after 3 attempts. Service $serviceName was not found; last choco exit code: $installExitCode."
        }

        Set-Service -Name $serviceName -StartupType Manual
        if ($service.Status -ne 'Running') {
            Start-Service -Name $serviceName
            $service = Get-Service -Name $serviceName
        }
        $service.WaitForStatus('Running', [TimeSpan]::FromSeconds(120))
        Set-Content -Path mssql_init -Value "initialized" -Encoding ASCII
    }
}
