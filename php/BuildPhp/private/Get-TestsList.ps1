function Get-TestsList {
    <#
    .SYNOPSIS
        Get the PHP test list.
    .PARAMETER OutputFile
        Output file
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Output file')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $OutputFile
    )
    begin {
    }
    process {
        Remove-Item $OutputFile -ErrorAction "Ignore"
        foreach ($line in Get-Content "$PSScriptRoot\..\config\test_directories") {
            $ttr = Get-ChildItem -Path $line -Filter "*.phpt" -Recurse
            foreach ($t in $ttr) {
                Add-Content $OutputFile ($t | Resolve-Path -Relative)
            }
        }
    }
    end {
    }
}