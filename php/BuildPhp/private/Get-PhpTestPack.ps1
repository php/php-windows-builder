function Get-PhpTestPack {
    <#
    .SYNOPSIS
        Get the PHP source code.
    .PARAMETER PhpVersion
        PHP Version
    .PARAMETER TestsDirectory
        Tests Directory
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='PHP Version')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $PhpVersion,
        [Parameter(Mandatory = $false, Position=1, HelpMessage='Tests Directory')]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $TestsDirectory
    )
    begin {
    }
    process {
        Add-Type -Assembly "System.IO.Compression.Filesystem"

        $versionInUrl = $PhpVersion
        if($PhpVersion -eq 'master' -or $PhpVersion -eq '8.5') {
            $fallbackBaseUrl = $baseUrl = "https://github.com/shivammathur/php-builder-windows/releases/download/master"
            $versionInUrl = "master"
        } else {
            $releaseState = if ($PhpVersion -match "[a-z]") {"qa"} else {"releases"}
            $baseUrl = "https://downloads.php.net/~windows/$releaseState"
            $fallbackBaseUrl = "https://downloads.php.net/~windows/$releaseState/archives"
        }
        $testZipFile = "php-test-pack-$versionInUrl.zip"
        $testUrl = "$baseUrl/$testZipFile"
        $fallBackUrl = "$fallbackBaseUrl/$testZipFile"

        try {
            Invoke-WebRequest $testUrl -OutFile $testZipFile
        } catch {
            try {
                Invoke-WebRequest $fallBackUrl -OutFile $testZipFile
            } catch {
                throw "Failed to download the test pack for PHP version $PhpVersion."
            }
        }

        $currentDirectory = (Get-Location).Path
        $testZipFilePath = Join-Path $currentDirectory $testZipFile
        $testsDirectoryPath = Join-Path $currentDirectory $TestsDirectory

        [System.IO.Compression.ZipFile]::ExtractToDirectory($testZipFilePath, $testsDirectoryPath)
    }
    end {
    }
}