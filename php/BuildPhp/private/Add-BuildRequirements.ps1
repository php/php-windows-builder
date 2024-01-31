function Add-BuildRequirements {
    <#
    .SYNOPSIS
        Get the PHP source code.
    .PARAMETER PhpVersion
        PHP Version
    .PARAMETER Arch
        PHP Architecture
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
        [string] $Arch
    )
    begin {
    }
    process {
        Get-OciSdk -Arch $Arch
        Get-PhpSdk
        Get-PhpSrc -PhpVersion $PhpVersion
    }
    end {
    }
}