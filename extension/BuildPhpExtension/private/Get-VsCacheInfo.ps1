function Get-VsCacheInfo {
    <#
    .SYNOPSIS
        Check if VS components need to be installed and set GitHub Actions outputs for caching.
    .PARAMETER PhpVersion
        PHP Version
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='PHP Version')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $PhpVersion
    )
    begin {
        $jsonPath = [System.IO.Path]::Combine($PSScriptRoot, '..\config\vs.json')
    }
    process {
        $VsConfig = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
        $majorMinor = if ($PhpVersion -eq 'master') { 'master' } else { $PhpVersion.Substring(0, 3) }
        $VsVersion = $VsConfig.php.$majorMinor
        $cacheRoot = if ([string]::IsNullOrWhiteSpace($env:RUNNER_TEMP)) { [System.IO.Path]::GetTempPath() } else { $env:RUNNER_TEMP }
        $cachePath = [System.IO.Path]::Combine($cacheRoot, 'vs-components', $VsVersion)
        $vsInstallPath = ''
        $needsInstall = $true
        $vsInstallPath = Get-VsInstallPath
        if (-not [string]::IsNullOrWhiteSpace($vsInstallPath)) {
            try {
                Get-VsVersionHelper -VsVersion $VsVersion -VsConfig $VsConfig | Out-Null
                $needsInstall = $false
            } catch {
            }
        }
        $components = $VsConfig.vs.$VsVersion.components -join ','
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($components)
        $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
        $componentHash = ([System.BitConverter]::ToString($hash).Replace('-', '').Substring(0, 16)).ToLower()
        $cachePath = Join-Path $cachePath $componentHash
        "needs-vs-install=$($needsInstall.ToString().ToLower())" >> $env:GITHUB_OUTPUT
        "vs-version=$VsVersion" >> $env:GITHUB_OUTPUT
        "vs-install-path=$vsInstallPath" >> $env:GITHUB_OUTPUT
        "vs-cache-path=$cachePath" >> $env:GITHUB_OUTPUT
        "vs-cache-key-prefix=vs-components-$VsVersion-$env:RUNNER_OS-$componentHash" >> $env:GITHUB_OUTPUT
    }
    end {
    }
}
