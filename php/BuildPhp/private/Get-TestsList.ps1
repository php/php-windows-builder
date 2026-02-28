function Get-TestsList {
    <#
    .SYNOPSIS
        Get the PHP test list.
    .PARAMETER OutputFile
        Output file
    .PARAMETER Type
        Test type
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Output file')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $OutputFile,
        [Parameter(Mandatory = $true, Position=1, HelpMessage='Test type')]
        [ValidateNotNull()]
        [ValidateSet('php', 'ext')]
        [string] $Type
    )
    begin {
    }
    process {
        Remove-Item $OutputFile -ErrorAction "Ignore"
        foreach ($line in Get-Content "$PSScriptRoot\..\config\${Type}_test_directories") {
            $ttr = Get-ChildItem -Path $line -Filter "*.phpt" -Recurse
            foreach ($t in $ttr) {
                Add-Content $OutputFile $t.FullName
            }
        }
    }
    end {
    }
}
