function Invoke-RestoreVsToolsetCache {
    <#
    .SYNOPSIS
        Restore the cached Visual Studio toolset into the active installation.
    .PARAMETER CachePath
        Cache staging path.
    .PARAMETER VsInstallPath
        Visual Studio installation path.
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Cache staging path')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $CachePath,
        [Parameter(Mandatory = $false, Position=1, HelpMessage='Visual Studio installation path')]
        [string] $VsInstallPath = ''
    )
    begin {
    }
    process {
        if ([string]::IsNullOrWhiteSpace($VsInstallPath)) {
            $VsInstallPath = Get-VsInstallPath
        }

        if ([string]::IsNullOrWhiteSpace($VsInstallPath)) {
            throw "Visual Studio installation path is not available."
        }

        $restored = Restore-VsToolsetFromCache -VsInstallPath $VsInstallPath -CachePath $CachePath
        if (-not $restored) {
            throw "Failed to restore the cached Visual Studio toolset."
        }
    }
    end {
    }
}
