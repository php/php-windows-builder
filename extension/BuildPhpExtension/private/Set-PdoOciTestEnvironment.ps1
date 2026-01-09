Function Set-PdoOciTestEnvironment {
    <#
    .SYNOPSIS
        Set up environment variables for pdo_oci extension tests
    .PARAMETER Config
        Extension Configuration
    #>
    [OutputType()]
    param(
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Extension Configuration')]
        [PSCustomObject] $Config
    )
    process {
        $currentDirectory = (Get-Location).Path
        $env:TEST_WORKERS = 1
        Get-PhpSrc -PhpVersion $Config.php_version

        # This test is not compatible with Oracle XE
        $testPath = "$currentDirectory\php-$($Config.php_version)-src\ext\pdo\tests\gh20553.phpt"
        if (Test-Path $testPath) {
            Remove-Item $testPath -Force
        }

        $env:PDO_TEST_DIR = "$currentDirectory\php-$($Config.php_version)-src\ext\pdo\tests"
        $env:PDO_OCI_TEST_DIR = "$currentDirectory\tests"
        $env:PDO_OCI_TEST_USER = "system"
        $env:PDO_OCI_TEST_PASS = "oracle"
        $env:PDO_OCI_TEST_DSN = "oci:dbname=localhost:1521/XEPDB1.localdomain;charset=AL32UTF8"
    }
}
