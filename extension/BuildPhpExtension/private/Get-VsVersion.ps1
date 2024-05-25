function Get-VsVersion {
    <#
    .SYNOPSIS
        Get the Visual Studio version.
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
        $jsonContent = Get-Content -Path $jsonPath -Raw
        $VsConfig = ConvertFrom-Json -InputObject $jsonContent
        $majorMinor = $PhpVersion.Substring(0, 3)
        $VsVersion = $($VsConfig.php.$majorMinor)

        if($null -eq (Get-Command vswhere -ErrorAction SilentlyContinue)) {
            throw "vswhere is not available"
        }
        $MSVCDirectory = vswhere -latest -find "VC\Tools\MSVC"
        $selectedToolset = $null
        $minor = $null
        foreach ($toolset in (Get-ChildItem $MSVCDirectory)) {
            $toolsetMajorVersion, $toolsetMinorVersion = $toolset.Name.split(".")[0,1]
            $requiredVs = $VsConfig.vs.$VsVersion
            if ($requiredVs.major -eq $toolsetMajorVersion -and ($null -eq $requiredVs.minor -or $toolsetMinorVersion -le $requiredVs.minor)) {
                if($null -eq $minor -or $toolsetMinorVersion -gt $minor)
                {
                    $selectedToolset = $toolset.Name.Trim()
                    $minor = $toolsetMinorVersion
                }
            }
        }
        if (-not $selectedToolset) {
            throw "toolset not available"
        }
        return [PSCustomObject]@{
            vs = $VsVersion
            toolset = $selectedToolset
        }
    }
    end {
    }
}