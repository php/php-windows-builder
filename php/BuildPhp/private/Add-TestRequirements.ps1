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
    .PARAMETER SourceRepository
        php-src repository to source tests from when SourceRef is provided.
    .PARAMETER SourceRef
        Optional branch, tag, or SHA in the custom php-src repository.
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
        [string] $ArtifactsDirectory,
        [Parameter(Mandatory = $false, Position=6, HelpMessage='php-src repository to source tests from when SourceRef is provided')]
        [string] $SourceRepository = 'php/php-src',
        [Parameter(Mandatory = $false, Position=7, HelpMessage='Optional branch, tag, or SHA in the custom php-src repository')]
        [string] $SourceRef = ''
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
        $useCustomSource = -not [string]::IsNullOrWhiteSpace($SourceRef)

        if(-not(Test-Path $binZipFilePath)) {
            Write-Host "Downloading PHP build $binZipFile..."
            $null = Get-PhpBuild -PhpVersion $PhpVersion -Arch $Arch -Ts $Ts -VsVersion $VsVersion
        } else {
            try {
                [System.IO.Compression.ZipFile]::ExtractToDirectory($binZipFilePath, $binDirectoryPath)
            } catch {
                7z x $binZipFilePath "-o$binDirectoryPath" -y | Out-Null
            }
        }

        if($useCustomSource -or -not(Test-Path $testZipFilePath)) {
            if($useCustomSource) {
                Write-Host "Downloading PHP tests from custom php-src source..."
            } else {
                Write-Host "Downloading PHP test pack $testZipFile..."
            }
            $null = Get-PhpTestPack -PhpVersion $PhpVersion `
                                    -TestsDirectory $TestsDirectory `
                                    -SourceRepository $SourceRepository `
                                    -SourceRef $SourceRef
        } else {
            try {
                [System.IO.Compression.ZipFile]::ExtractToDirectory($testZipFilePath, $testsDirectoryPath)
            } catch {
                7z x $testZipFilePath "-o$testsDirectoryPath" -y | Out-Null
            }
        }

        $compatVersion = $PhpVersion
        $versionFilePath = Join-Path $testsDirectoryPath 'main\php_version.h'
        if (Test-Path -Path $versionFilePath) {
            $versionContent = Get-Content -Path $versionFilePath -Raw
            $majorMatch = [regex]::Match($versionContent, 'PHP_MAJOR_VERSION\s+(\d+)')
            $minorMatch = [regex]::Match($versionContent, 'PHP_MINOR_VERSION\s+(\d+)')
            if ($majorMatch.Success -and $minorMatch.Success) {
                $compatVersion = "$($majorMatch.Groups[1].Value).$($minorMatch.Groups[1].Value)"
            }
        }

        $compatPatchApplied = $true
        $testSettings = Get-TestSettings -PhpVersion $compatVersion
        $compatPatchName = if ($testSettings.PSObject.Properties.Name -contains 'compatPatch') { $testSettings.compatPatch } else { '' }
        if (-not [string]::IsNullOrWhiteSpace($compatPatchName)) {
            $compatPatchPath = Join-Path $PSScriptRoot "..\config\run-tests\$compatPatchName"
            if(-not(Test-Path -Path $compatPatchPath)) {
                throw "Compatibility run-tests patch not found: $compatPatchPath"
            }

            $compatPatchApplied = Invoke-CompatRunTestsPatch `
                -Path (Join-Path $testsDirectoryPath 'run-tests.php') `
                -PatchPath $compatPatchPath
            if ($compatPatchApplied) {
                Write-Host "Applied compatibility run-tests patch ($compatPatchName) in $testsDirectoryPath"
            } else {
                $warningMessage = "Failed to patch the runner for handling worker crashes, defaulting to 2 workers."
                Write-Warning $warningMessage
                if ($env:GITHUB_ACTIONS -eq 'true') {
                    Write-Host "::warning $warningMessage"
                }
            }
        }

        $FetchDeps = $False
        if($null -eq $env:DEPS_DIR) {
            $env:DEPS_DIR = "C:\deps-$PhpVersion-$Arch"
            $FetchDeps = $True
        }
        if($FetchDeps -eq $True -or $null -eq $Env:DEPS_CACHE_HIT -or $Env:DEPS_CACHE_HIT -ne 'true') {
            $null = Add-PhpDeps -PhpVersion $PhpVersion -VsVersion $VsVersion -Arch $Arch -Destination $env:DEPS_DIR
        }
        $null = Invoke-EditBin -Exe "$binDirectoryPath\php.exe" -StackSize 8388608 -Arch $Arch
        $null = Invoke-EditBin -Exe "$binDirectoryPath\php-cgi.exe" -StackSize 8388608 -Arch $Arch
        $null = Add-Path "$env:DEPS_DIR\bin"
        return [PSCustomObject]@{
            CompatPatchApplied = $compatPatchApplied
        }
    }
    end {
    }
}
