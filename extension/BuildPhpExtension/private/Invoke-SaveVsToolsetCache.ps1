function Invoke-SaveVsToolsetCache {
    <#
    .SYNOPSIS
        Stage the selected Visual Studio toolset for GitHub Actions caching.
    .PARAMETER PhpVersion
        PHP Version.
    .PARAMETER CachePath
        Cache staging path.
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='PHP Version')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $PhpVersion,
        [Parameter(Mandatory = $true, Position=1, HelpMessage='Cache staging path')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $CachePath
    )
    begin {
    }
    process {
        $vsInstallPath = Get-VsInstallPath
        if ([string]::IsNullOrWhiteSpace($vsInstallPath)) {
            throw "Visual Studio installation path is not available."
        }

        $vsData = Get-VsVersion -PhpVersion $PhpVersion
        Sync-VsToolsetCache -VsInstallPath $vsInstallPath -CachePath $CachePath -Toolset $vsData.toolset
    }
    end {
    }
}
