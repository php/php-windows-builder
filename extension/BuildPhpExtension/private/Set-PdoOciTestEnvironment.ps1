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
        $phpTestsDirectory = Join-Path $currentDirectory "php-$($Config.php_version)-src"
        if($Config.PSObject.Properties['php_test_pack_url'] -and $Config.php_test_pack_url) {
            $testPack = Join-Path $currentDirectory "php-test-pack-$($Config.php_version).zip"
            Get-File -Url $Config.php_test_pack_url -OutFile $testPack
            Expand-Archive -LiteralPath $testPack -DestinationPath $phpTestsDirectory -Force
        } else {
            Get-PhpSrc -PhpVersion $Config.php_version
        }
        $pdoTestsDirectory = Join-Path $phpTestsDirectory 'ext\pdo\tests'

        # This test is not compatible with Oracle XE
        $testPath = Join-Path $pdoTestsDirectory 'gh20553.phpt'
        if (Test-Path $testPath) {
            Remove-Item $testPath -Force
        }

        $env:PDO_TEST_DIR = $pdoTestsDirectory
        $env:PDO_OCI_TEST_DIR = "$currentDirectory\tests"
        $env:PDO_OCI_TEST_USER = "system"
        $env:PDO_OCI_TEST_PASS = "oracle"
        $env:PDO_OCI_TEST_DSN = "oci:dbname=localhost:1521/XEPDB1.localdomain;charset=AL32UTF8"
    }
}
