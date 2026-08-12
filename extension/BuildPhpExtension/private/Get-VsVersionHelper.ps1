function Get-VsVersionHelper {
    <#
    .SYNOPSIS
        Helper to get the Visual Studio version and toolset.
    .PARAMETER VsConfig
        Visual Studio Configuration
    .PARAMETER VsVersion
        Visual Studio Version
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Visual Studio Version')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $VsVersion,
        [Parameter(Mandatory = $true, Position=1, HelpMessage='Visual Studio Configuration')]
        [PSCustomObject] $VsConfig
    )
    begin {
    }
    process {
        $installerDir = Join-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio" 'Installer'
        $vswherePath = Join-Path $installerDir 'vswhere.exe'
        if (-not (Test-Path $vswherePath)) {
            throw "vswhere is not available"
        }
        $selectedToolset = $null
        $minor = $null
        $requiredChannel = [int]($VsVersion -replace '\D', '')
        $requiredVs = $VsConfig.vs.$VsVersion
        $instances = @(& $vswherePath -products '*' -format json 2> $null | ConvertFrom-Json)
        foreach ($vsInst in $instances) {
            if ([int]$vsInst.installationVersion.Split('.')[0] -lt $requiredChannel) {
                continue
            }
            $MSVCDirectory = Join-Path $vsInst.installationPath 'VC\Tools\MSVC'
            if (-not (Test-Path $MSVCDirectory)) {
                continue
            }
            foreach ($toolset in (Get-ChildItem $MSVCDirectory)) {
                $toolsetMajorVersion, $toolsetMinorVersion = $toolset.Name.split(".")[0,1]
                $majorVersionCheck = [int]$requiredVs.major -eq [int]$toolsetMajorVersion
                $minorLowerBoundCheck = [int]$toolsetMinorVersion -ge [int]$requiredVs.minorMin
                $minorUpperBoundCheck = ($null -eq $requiredVs.minorMax) -or ([int]$toolsetMinorVersion -le [int]$requiredVs.minorMax)
                if ($majorVersionCheck -and $minorLowerBoundCheck -and $minorUpperBoundCheck) {
                    if($null -eq $minor -or [int]$toolsetMinorVersion -gt [int]$minor) {
                        $selectedToolset = $toolset.Name.Trim()
                        $minor = $toolsetMinorVersion
                    }
                }
            }
        }

        if (-not $selectedToolset) {
            throw "toolset not available"
        }

        return $selectedToolset
    }
    end {
    }
}
