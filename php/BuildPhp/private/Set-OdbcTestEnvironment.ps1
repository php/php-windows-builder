function Set-OdbcTestEnvironment {
    <#
    .SYNOPSIS
        Configure environment variables for ODBC/PDO ODBC SQL Server tests.
    #>
    [CmdletBinding()]
    param ()
    process {
        Set-MsSqlTestEnvironment

        $env:ODBC_TEST_USER = 'sa'
        $env:ODBC_TEST_PASS = 'Password12!'
        $env:ODBC_TEST_DSN  = "Driver={ODBC Driver 17 for SQL Server};Server=(local)\SQLEXPRESS;Database=master;uid=$($env:ODBC_TEST_USER);pwd=$($env:ODBC_TEST_PASS)"
        $env:PDO_ODBC_TEST_DSN = "odbc:$($env:ODBC_TEST_DSN)"
        $env:PDO_ODBC_TEST_USER = $env:ODBC_TEST_USER
        $env:PDO_ODBC_TEST_PASS = $env:ODBC_TEST_PASS
    }
}
