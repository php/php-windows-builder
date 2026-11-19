Function Test-ClangToolset {
    <#
    .SYNOPSIS
        Check whether the PHP version is built with the clang-cl toolset.
    .PARAMETER PhpVersion
        PHP Version
    #>
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true, Position=0, HelpMessage='PHP Version')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $PhpVersion
    )
    begin {
    }
    process {
        if ($PhpVersion -eq 'master') {
            return $true
        }
        if ($PhpVersion -notmatch '^(\d+\.\d+(?:\.\d+)?)') {
            return $false
        }
        return [version] $matches[1] -ge [version] '8.6'
    }
    end {
    }
}
