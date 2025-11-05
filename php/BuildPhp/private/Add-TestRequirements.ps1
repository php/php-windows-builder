function Add-TestRequirements {
    <#
    .SYNOPSIS
        Set the PHP test requirements.
    .PARAMETER PhpVersion
        PHP Version
    .PARAMETER Arch
        PHP Architecture
    .PARAMETER Ts
        PHP Build Type
    .PARAMETER VsVersion
        VS Version
    .PARAMETER TestsDirectory
        Tests Directory
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
        [string] $VsVersion,
        [Parameter(Mandatory = $false, Position=4, HelpMessage='Tests Directory')]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $TestsDirectory,
        [Parameter(Mandatory = $true, Position=5, HelpMessage='Artifacts Directory')]
        [ValidateNotNull()]
        [string] $ArtifactsDirectory
    )
    begin {
    }
    process {
        Add-Type -Assembly "System.IO.Compression.Filesystem"
        $versionInUrl = $PhpVersion
        if($PhpVersion -eq 'master') {
            $versionInUrl = "master"
        }
        $tsPart = if ($Ts -eq "nts") {"nts-Win32"} else {"Win32"}
        $binZipFile = "php-$versionInUrl-$tsPart-$VsVersion-$Arch.zip"
        $testZipFile = "php-test-pack-$versionInUrl.zip"

        $currentDirectory = (Get-Location).Path
        $binZipFilePath = Join-Path $ArtifactsDirectory $binZipFile
        $binDirectoryPath = Join-Path $currentDirectory phpbin

        $testZipFilePath = Join-Path $ArtifactsDirectory $testZipFile
        $testsDirectoryPath = Join-Path $currentDirectory $TestsDirectory

        if(-not(Test-Path $binZipFilePath)) {
            Write-Host "Downloading PHP build $binZipFile..."
            Get-PhpBuild -PhpVersion $PhpVersion -Arch $Arch -Ts $Ts -VsVersion $VsVersion
        } else {
            [System.IO.Compression.ZipFile]::ExtractToDirectory($binZipFilePath, $binDirectoryPath)
        }

        if(-not(Test-Path $testZipFilePath)) {
            Write-Host "Downloading PHP test pack $testZipFile..."
            Get-PhpTestPack -PhpVersion $PhpVersion -TestsDirectory $TestsDirectory
        } else {
            [System.IO.Compression.ZipFile]::ExtractToDirectory($testZipFilePath, $testsDirectoryPath)
        }

        Get-PhpSdk
        $FetchDeps = $False
        if($null -eq $env:DEPS_DIR) {
            $majorMinorVersion = ($PhpVersion -split '\.')[0..1] -join '.'
            $env:DEPS_DIR = "C:\deps-$majorMinorVersion-$Arch"
            $FetchDeps = $True
        }
        if(-not(Test-Path $env:DEPS_DIR)) {
            New-Item "$env:DEPS_DIR" -ItemType "directory" -Force > $null 2>&1
        }
        $branch = if ($PhpVersion -eq 'master') {'master'} else {($PhpVersion -split '\.')[0..1] -join '.'}
        $env:PHP_SDK_VS = $VsVersion
        $env:PHP_SDK_ARCH = $Arch
        $bat_content = @()
        if($FetchDeps -eq $True -or $null -eq $Env:DEPS_CACHE_HIT -or $Env:DEPS_CACHE_HIT -ne 'true') {
            $bat_content += "cmd /c phpsdk_deps --update --force --no-backup --branch $branch --stability staging --deps $env:DEPS_DIR"
        }
        $bat_content += "editbin /stack:8388608 $binDirectoryPath\php.exe"
        $bat_content += "editbin /stack:8388608 $binDirectoryPath\php-cgi.exe"
        Set-Content -Encoding "ASCII" -Path vs.bat -Value $bat_content
        & "$currentDirectory\php-sdk\phpsdk-starter.bat" -c $VsVersion -a $Arch -t vs.bat
        Add-Path "$env:DEPS_DIR\bin"
    }
    end {
    }
}