function Sync-VsToolsetCache {
    <#
    .SYNOPSIS
        Stage a Visual Studio toolset for GitHub Actions caching.
    .PARAMETER VsInstallPath
        Visual Studio installation path.
    .PARAMETER CachePath
        Cache staging path.
    .PARAMETER Toolset
        Toolset version directory name.
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Visual Studio installation path')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $VsInstallPath,
        [Parameter(Mandatory = $true, Position=1, HelpMessage='Cache staging path')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $CachePath,
        [Parameter(Mandatory = $true, Position=2, HelpMessage='Toolset directory')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Toolset
    )
    begin {
    }
    process {
        $sourcePath = Join-Path (Join-Path $VsInstallPath 'VC\Tools\MSVC') $Toolset
        if (-not (Test-Path $sourcePath)) {
            return
        }

        if (-not (Test-Path $CachePath)) {
            New-Item -Path $CachePath -ItemType Directory -Force | Out-Null
        }

        $toolsetCacheDirectory = Join-Path $CachePath 'toolset'
        if (Test-Path $toolsetCacheDirectory) {
            Remove-Item -Path $toolsetCacheDirectory -Recurse -Force
        }
        New-Item -Path $toolsetCacheDirectory -ItemType Directory -Force | Out-Null

        Copy-Item -Path $sourcePath -Destination $toolsetCacheDirectory -Recurse -Force
        Set-Content -Path (Join-Path $CachePath 'toolset.txt') -Value $Toolset -NoNewline
    }
    end {
    }
}
