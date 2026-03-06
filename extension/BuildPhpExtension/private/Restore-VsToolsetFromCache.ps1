function Restore-VsToolsetFromCache {
    <#
    .SYNOPSIS
        Restore a cached Visual Studio toolset into the active VS installation.
    .PARAMETER VsInstallPath
        Visual Studio installation path.
    .PARAMETER CachePath
        Cache staging path.
    #>
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Visual Studio installation path')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $VsInstallPath,
        [Parameter(Mandatory = $true, Position=1, HelpMessage='Cache staging path')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $CachePath
    )
    begin {
    }
    process {
        $metadataPath = Join-Path $CachePath 'toolset.txt'
        if (-not (Test-Path $metadataPath)) {
            return $false
        }

        $toolset = (Get-Content -Path $metadataPath -Raw).Trim()
        if ([string]::IsNullOrWhiteSpace($toolset)) {
            return $false
        }

        $sourcePath = Join-Path (Join-Path $CachePath 'toolset') $toolset
        if (-not (Test-Path $sourcePath)) {
            return $false
        }

        $msvcDirectory = Join-Path $VsInstallPath 'VC\Tools\MSVC'
        if (-not (Test-Path $msvcDirectory)) {
            New-Item -Path $msvcDirectory -ItemType Directory -Force | Out-Null
        }

        $destinationPath = Join-Path $msvcDirectory $toolset
        if (-not (Test-Path $destinationPath)) {
            Copy-Item -Path $sourcePath -Destination $msvcDirectory -Recurse -Force
        }

        return (Test-Path $destinationPath)
    }
    end {
    }
}
