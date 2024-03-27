function Get-PhpBuild {
    <#
    .SYNOPSIS
        Get the PHP build.
    .PARAMETER PhpVersion
        PHP Version
    .PARAMETER Arch
        PHP Architecture
    .PARAMETER Ts
        PHP Build Type
    .PARAMETER VsVersion
        VS Version
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='PHP Version')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $PhpVersion,
        [Parameter(Mandatory = $true, Position=1, HelpMessage='PHP Architecture')]
        [ValidateNotNull()]
        [ValidateSet('x86', 'x64')]
        [string] $Arch,
        [Parameter(Mandatory = $true, Position=2, HelpMessage='PHP Build Type')]
        [ValidateNotNull()]
        [ValidateSet('nts', 'ts')]
        [string] $Ts,
        [Parameter(Mandatory = $false, Position=3, HelpMessage='VS Version')]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $VsVersion
    )
    begin {
    }
    process {
        Add-Type -Assembly "System.IO.Compression.Filesystem"

        if($null -eq $VsVersion) {
            $VsVersion = (Get-VsVersion -PhpVersion $PhpVersion)
            if($null -eq $VsVersion) {
                throw "PHP version $PhpVersion is not supported."
            }
        }

        $releaseState = if ($PhpVersion -match "[a-z]") {"qa"} else {"releases"}
        $baseUrl = "https://downloads.php.net/~windows/$releaseState"
        $fallbackBaseUrl = "https://downloads.php.net/~windows/$releaseState/archives"
        $tsPart = if ($Ts -eq "nts") {"nts-Win32"} else {"Win32"}
        $binZipFile = "php-$PhpVersion-$tsPart-$VsVersion-$Arch.zip"
        $binUrl = "$baseUrl/$binZipFile"
        $fallBackUrl = "$fallbackBaseUrl/$binZipFile"

        try {
            Invoke-WebRequest $binUrl -OutFile $binZipFile
        } catch {
            try {
                Invoke-WebRequest $fallBackUrl -OutFile $binZipFile
            } catch {
                throw "Failed to download the build for PHP version $PhpVersion."
            }
        }

        $currentDirectory = (Get-Location).Path
        $binZipFilePath = Join-Path $currentDirectory $binZipFile
        $binDirectoryPath = Join-Path $currentDirectory phpbin

        [System.IO.Compression.ZipFile]::ExtractToDirectory($binZipFilePath, $binDirectoryPath)
    }
    end {
    }
}