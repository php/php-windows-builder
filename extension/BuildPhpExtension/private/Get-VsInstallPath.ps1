function Get-VsInstallPath {
    <#
    .SYNOPSIS
        Get the latest Visual Studio installation path.
    #>
    [OutputType([string])]
    param ()
    begin {
    }
    process {
        $installerDir = Join-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio" 'Installer'
        $vswherePath = Join-Path $installerDir 'vswhere.exe'
        if (-not (Test-Path $vswherePath)) {
            return ''
        }

        $vsInstallPath = & $vswherePath -latest -products * -property installationPath 2>$null | Select-Object -First 1
        if ($null -eq $vsInstallPath) {
            return ''
        }

        return $vsInstallPath.Trim()
    }
    end {
    }
}
