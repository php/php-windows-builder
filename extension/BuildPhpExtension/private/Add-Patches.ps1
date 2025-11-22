Function Add-Patches {
    <#
    .SYNOPSIS
        Add patches to the extension source
    .PARAMETER PatchPath
        Path to the patch script
    #>
    [OutputType()]
    param(
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Path to the patch script')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $PatchPath
    )
    begin {
    }
    process {
        # Apply patches only for php/php-windows-builder and shivammathur/php-windows-builder
        if($null -ne $env:GITHUB_REPOSITORY) {
            if($env:GITHUB_REPOSITORY -eq 'php/php-windows-builder' -or $env:GITHUB_REPOSITORY -eq 'shivammathur/php-windows-builder') {
                if(Test-Path -PATH $PSScriptRoot\..\patches\$PatchPath) {
                    . $PSScriptRoot\..\patches\$PatchPath
                }
            }
        }
    }
    end {
    }
}