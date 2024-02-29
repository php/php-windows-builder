function Get-PhpBuild {
    <#
    .SYNOPSIS
        Get the PHP build.
    .PARAMETER Config
        Extension Configuration
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Configuration for the extension')]
        [PSCustomObject] $Config
    )
    begin {
    }
    process {
        Add-Type -Assembly "System.IO.Compression.Filesystem"

        $releaseState = if ($Config.php_version -match "[a-z]") {"qa"} else {"releases"}
        $baseUrl = "https://windows.php.net/downloads/$releaseState"
        $fallbackBaseUrl = "https://windows.php.net/downloads/$releaseState/archives"
        $tsPart = if ($Config.ts -eq "nts") {"nts-Win32"} else {"Win32"}
        $releases = Invoke-WebRequest "$baseUrl/releases.json" | ConvertFrom-Json
        $phpSemver = $releases.$($Config.php_version).version
        $binZipFile = "php-$phpSemver-$tsPart-$($Config.vs_version)-$($Config.arch).zip"
        $binUrl = "$baseUrl/$binZipFile"

        $fallBackUrl = "$fallbackBaseUrl/$binZipFile"

        try {
            Invoke-WebRequest $binUrl -OutFile $binZipFile
        } catch {
            try {
                Invoke-WebRequest $fallBackUrl -OutFile $binZipFile
            } catch {
                throw "Failed to download the build for PHP version $($Config.php_version)."
            }
        }

        $currentDirectory = (Get-Location).Path
        $binZipFilePath = Join-Path $currentDirectory $binZipFile
        $binDirectoryPath = Join-Path $currentDirectory php-bin

        [System.IO.Compression.ZipFile]::ExtractToDirectory($binZipFilePath, $binDirectoryPath)
        Add-Path -PathItem $binDirectoryPath
        return $binDirectoryPath
    }
    end {
    }
}