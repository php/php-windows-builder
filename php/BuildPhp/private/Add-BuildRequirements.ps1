function Add-BuildRequirements {
    <#
    .SYNOPSIS
        Get the PHP source code.
    .PARAMETER PhpVersion
        PHP Version
    .PARAMETER Arch
        PHP Architecture
    .PARAMETER FetchSrc
        Fetch PHP source code
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='PHP Version')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $PhpVersion,
        [Parameter(Mandatory = $true, Position=1, HelpMessage='PHP Architecture')]
        [ValidateNotNull()]
        [ValidateSet('x86', 'x64')]
        [string] $Arch,
        [Parameter(Mandatory = $false, Position=2, HelpMessage='Fetch PHP source code')]
        [ValidateNotNull()]
        [bool] $FetchSrc = $True
    )
    begin {
    }
    process {
        Get-OciSdk -Arch $Arch
        Get-PhpSdk
        if($FetchSrc) {
            Get-PhpSrc -PhpVersion $PhpVersion
        }
    }
    end {
    }
}