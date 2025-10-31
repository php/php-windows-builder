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

        $ldapDll = Join-Path $binDirectoryPath 'php_ldap.dll'
        Remove-Item -LiteralPath $ldapDll -Force -ErrorAction SilentlyContinue

        $phpExePath = Join-Path $binDirectoryPath 'php.exe'
        $phpCgiPath = Join-Path $binDirectoryPath 'php-cgi.exe'
        try { & editbin "/stack:8388608" $phpExePath | Out-Null } catch {}
        try { & editbin "/stack:8388608" $phpCgiPath | Out-Null } catch {}

        $Env:TEST_PHPDBG_EXECUTABLE = (Join-Path $binDirectoryPath 'phpdbg.exe')

        Get-PhpSdk
        $env:DEPS_DIR = "$currentDirectory/../deps"
        New-Item "$env:DEPS_DIR" -ItemType "directory" -Force > $null 2>&1
        $branch = if ($PhpVersion -eq 'master') {'master'} else {($PhpVersion -split '\.')[0..1] -join '.'}
        & "$currentDirectory\php-sdk\bin\phpsdk_deps.bat" --update --no-backup --branch $branch --stability staging --deps $env:DEPS_DIR --crt $VsVersion --arch $Arch

        Set-MySqlTestEnvironment
        Set-PgSqlTestEnvironment
        Set-OdbcTestEnvironment
        Set-MsSqlTestEnvironment
        Set-FirebirdTestEnvironment
        Set-EnchantTestEnvironment
        Set-SnmpTestEnvironment -TestsDirectoryPath $testsDirectoryPath
    }
    end {
    }
}