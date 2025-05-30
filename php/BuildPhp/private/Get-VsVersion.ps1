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
        $versions = ConvertFrom-Json -InputObject $jsonContent
        if($PhpVersion -eq 'master') { $key = 'master'; } else { $key = $PhpVersion.Substring(0, 3); }
        return $($versions.$key)
    }
    end {
    }
}