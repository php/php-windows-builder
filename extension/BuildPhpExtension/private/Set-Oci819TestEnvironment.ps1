Function Set-Oci819TestEnvironment {
    <#
    .SYNOPSIS
        Set up environment variables for oci8_19 extension tests
    .PARAMETER Config
        Extension Configuration
    #>
    [OutputType()]
    param(
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Extension Configuration')]
        [PSCustomObject] $Config
    )
    process {
        $env:PHP_OCI8_TEST_USER = "system"
        $env:PHP_OCI8_TEST_PASS = "oracle"
        $env:PHP_OCI8_TEST_DB = "localhost:1521/XEPDB1.localdomain"
    }
}
