function Add-WindowsTestHelpers {
    <#
    .SYNOPSIS
        Ensure Windows-specific test helper executables exist.
    .PARAMETER TestsDirectoryPath
        Root path of the extracted php-src test tree.
    .PARAMETER Arch
        Target architecture for the Windows helper executable.
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Tests directory path')]
        [ValidateNotNullOrEmpty()]
        [string] $TestsDirectoryPath,
        [Parameter(Mandatory = $true, Position=1, HelpMessage='Target architecture')]
        [ValidateSet('x86', 'x64')]
        [string] $Arch
    )
    process {
        if ($env:OS -ne 'Windows_NT') {
            return
        }

        $helpersDirectory = Join-Path $TestsDirectoryPath 'ext\standard\tests\helpers'
        $badCmdSource = Join-Path $helpersDirectory 'bad_cmd.c'
        $badCmdExe = Join-Path $helpersDirectory 'bad_cmd.exe'

        if (-not (Test-Path -LiteralPath $badCmdSource) -or (Test-Path -LiteralPath $badCmdExe)) {
            return
        }

        $installerDir = Join-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio" 'Installer'
        $vswherePath = Join-Path $installerDir 'vswhere.exe'
        if (-not (Test-Path -LiteralPath $vswherePath)) {
            throw "vswhere is not available to generate Windows test helper $badCmdExe"
        }

        $vsInstallationPath = (& $vswherePath -latest -products (Get-VsProductIds) -property installationPath | Select-Object -First 1).Trim()
        if ([string]::IsNullOrWhiteSpace($vsInstallationPath)) {
            throw "Visual Studio installation path could not be determined for Windows test helper generation"
        }

        $vcVarsPath = Join-Path $vsInstallationPath 'VC\Auxiliary\Build\vcvarsall.bat'
        if (-not (Test-Path -LiteralPath $vcVarsPath)) {
            throw "vcvarsall.bat was not found at $vcVarsPath"
        }

        # Match php-src's Windows helper generation by compiling bad_cmd.c with MSVC.
        $compileCommand = "call `"$vcVarsPath`" $Arch >nul && cd /d `"$helpersDirectory`" && cl /nologo bad_cmd.c"
        & cmd.exe /d /s /c $compileCommand 2>&1 | ForEach-Object { Write-Host $_ }
        if ($LASTEXITCODE) {
            throw "MSVC compilation failed with exit code $LASTEXITCODE while generating $badCmdExe"
        }

        if (-not (Test-Path -LiteralPath $badCmdExe)) {
            throw "Failed to generate Windows test helper: $badCmdExe"
        }

        Write-Host "Generated Windows test helper $badCmdExe"
    }
}
