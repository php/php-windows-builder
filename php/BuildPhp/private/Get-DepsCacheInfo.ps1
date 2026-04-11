function Get-DepsCacheInfo {
    <#
    .SYNOPSIS
        Get dependency cache metadata for a PHP build.
    .PARAMETER PhpVersion
        PHP version (e.g., 8.4.18 or master).
    .PARAMETER Arch
        Target architecture: x86 or x64.
    .PARAMETER LibsBuildRuns
        Optional comma-separated workflow run IDs used for library overrides.
    .PARAMETER IncludeDefaultRunsKey
        Append "default" to the cache key when no workflow run IDs are provided.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $PhpVersion,
        [Parameter(Mandatory=$true)]
        [ValidateSet('x86','x64')]
        [string] $Arch,
        [Parameter(Mandatory=$false)]
        [string] $LibsBuildRuns = '',
        [Parameter(Mandatory=$false)]
        [switch] $IncludeDefaultRunsKey
    )

    process {
        $depsPhpVersion = $PhpVersion
        if ($PhpVersion -ne 'master') {
            $versionParts = $PhpVersion.Split('.')
            if ($versionParts.Count -ge 2) {
                $depsPhpVersion = $versionParts[0..1] -join '.'
            }
        }

        $runsKey = ''
        $normalizedRuns = @($LibsBuildRuns -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }) -join ','
        if ($normalizedRuns) {
            $runsKey = [System.Convert]::ToHexString(
                [System.Security.Cryptography.SHA256]::HashData(
                    [System.Text.Encoding]::UTF8.GetBytes($normalizedRuns)
                )
            ).ToLowerInvariant().Substring(0, 16)
        } elseif ($IncludeDefaultRunsKey) {
            $runsKey = 'default'
        }

        $vsVersion = (Get-VsVersion -PhpVersion $PhpVersion).vs
        $packageData = Get-PhpDepsPackages -PhpVersion $PhpVersion -VsVersion $vsVersion -Arch $Arch

        $cacheKey = "deps-$depsPhpVersion-$Arch"
        if ($runsKey) {
            $cacheKey += "-$runsKey"
        }

        return [PSCustomObject]@{
            PhpVersion = $PhpVersion
            DepsPhpVersion = $depsPhpVersion
            VsVersion = $vsVersion
            CacheKey = $cacheKey
            CacheDir = "C:\deps-$depsPhpVersion-$Arch"
            Packages = @($packageData.Packages)
            OverrideLibraries = @($packageData.OverrideLibraries)
        }
    }
}
