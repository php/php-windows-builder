function Invoke-PhpSmokeTests {
    <#
    .SYNOPSIS
        Run smoke tests for PHP build artifacts.
    .PARAMETER ArtifactsDirectory
        Directory containing PHP build zip artifacts.
    .PARAMETER Arch
        PHP architecture filter.
    .PARAMETER Ts
        PHP thread safety filter.
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Artifacts directory')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $ArtifactsDirectory,
        [Parameter(Mandatory = $true, Position=1, HelpMessage='PHP Architecture')]
        [ValidateSet('x86', 'x64')]
        [string] $Arch,
        [Parameter(Mandatory = $true, Position=2, HelpMessage='PHP Build Type')]
        [ValidateSet('nts', 'ts')]
        [string] $Ts
    )
    begin {
    }
    process {
        $artifactsPath = (Resolve-Path $ArtifactsDirectory).Path
        $tempRoot = Join-Path $env:TEMP ("php-smoke-" + [System.Guid]::NewGuid().ToString())
        New-Item -Path $tempRoot -ItemType "directory" -Force > $null 2>&1
        $requiredPhpModulesConfig = Join-Path $PSScriptRoot '..\config\smoke_test_modules'
        $requiredPhpModules = @(
            Get-Content -Path $requiredPhpModulesConfig |
                ForEach-Object { "$_".Trim() } |
                Where-Object { $_ -and -not $_.StartsWith('#') }
        )
        if(-not $requiredPhpModules) {
            throw "No smoke test modules configured in $requiredPhpModulesConfig"
        }

        $zipPattern = "php-*-$Arch.zip"
        $zipRegex = if($Ts -eq 'nts') {
            "^php-[^-]+-nts-Win32-vs\d+-${Arch}\.zip$"
        } else {
            "^php-[^-]+-Win32-vs\d+-${Arch}\.zip$"
        }
        $zipMatches = @(
            Get-ChildItem -Path $artifactsPath -Filter $zipPattern -File |
                Where-Object {
                    $_.Name -match $zipRegex
                } |
                Sort-Object Name
        )

        if(-not $zipMatches) {
            throw "No PHP build archive matched regex '$zipRegex' in $artifactsPath"
        }

        if($zipMatches.Count -ne 1) {
            throw "Expected exactly one PHP build archive for arch=$Arch ts=$Ts, found $($zipMatches.Count): $($zipMatches.Name -join ', ')"
        }

        $zip = $zipMatches[0]

        $extractPath = Join-Path $tempRoot $zip.BaseName
        New-Item -Path $extractPath -ItemType "directory" -Force > $null 2>&1

        try {
            Expand-Archive -Path $zip.FullName -DestinationPath $extractPath -Force
        } catch {
            7z x $zip.FullName "-o$extractPath" -y | Out-Null
        }

        $phpExe = Join-Path $extractPath 'php.exe'
        if(-not(Test-Path $phpExe)) {
            throw "php.exe not found in $($zip.Name)"
        }

        $extDir = Join-Path $extractPath 'ext'
        if(-not(Test-Path $extDir)) {
            throw "Extension directory not found for $($zip.Name) at $extDir"
        }

        $iniPath = Join-Path $extractPath 'php.ini'
        Set-Content -Path $iniPath -Value @(
            ('extension_dir="{0}"' -f $extDir)
        ) -Encoding ascii

        Get-ChildItem -Path $extDir -Filter 'php_*.dll' -File |
            Sort-Object Name |
            ForEach-Object {
                if(
                    $_.Name -in @('php_pdo_firebird.dll', 'php_snmp.dll', 'php_pdo_oci.dll') -or
                    $_.Name -like 'php_oci8*.dll'
                ) {
                    Write-Host "Skipping $($_.Name) in smoke tests"
                } elseif($_.Name -eq 'php_opcache.dll') {
                    Add-Content -Path $iniPath -Value ('zend_extension={0}' -f $_.Name) -Encoding ascii
                } else {
                    Add-Content -Path $iniPath -Value ('extension={0}' -f $_.Name) -Encoding ascii
                }
            }

        Write-Host "Running smoke tests for $($zip.Name)"
        Push-Location $extractPath
        try {
            & .\php.exe -c $iniPath -v
            if(-not $?) {
                throw "php -v failed for $($zip.Name)"
            }

            $phpModulesOutput = & .\php.exe -c $iniPath -m
            if(-not $?) {
                throw "php -m failed for $($zip.Name)"
            }
            $phpModulesOutput | ForEach-Object { Write-Host $_ }

            # Validate the modules that PHP actually loaded, not just DLL files present on disk.
            $loadedPhpModules = @(
                $phpModulesOutput |
                    ForEach-Object { "$_".Trim() } |
                    Where-Object { $_ -and $_ -notmatch '^\[.*\]$' }
            )
            $loadedPhpModulesLookup = @{}
            foreach($moduleName in $loadedPhpModules) {
                $loadedPhpModulesLookup[$moduleName.ToLowerInvariant()] = $true
            }

            $missingPhpModules = @()
            foreach($requiredModule in $requiredPhpModules) {
                if(-not $loadedPhpModulesLookup.ContainsKey($requiredModule.ToLowerInvariant())) {
                    $missingPhpModules += $requiredModule
                }
            }

            if($missingPhpModules) {
                throw "php -m missing required modules for $($zip.Name): $($missingPhpModules -join ', ')"
            }

            & .\php.exe -c $iniPath -i
            if(-not $?) {
                throw "php -i failed for $($zip.Name)"
            }
        } finally {
            Pop-Location
        }
    }
    end {
    }
}
