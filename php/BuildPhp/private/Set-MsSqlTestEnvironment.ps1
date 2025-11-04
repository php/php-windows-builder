function Set-MsSqlTestEnvironment {
    <#
    .SYNOPSIS
        Install Microsoft SQL Server Express required for SQL Server-related tests.
    #>
    [CmdletBinding()]
    param ()
    process {
        & choco install sql-server-express -y --no-progress --install-arguments="/SECURITYMODE=SQL /SAPWD=Password12!"
    }
}

