function Get-TestSettings {
    <#
    .SYNOPSIS
        Get the PHP test settings.
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
        $settings = $null
    }
    process {
        $workers = $Env:NUMBER_OF_PROCESSORS / 2 * 3

        $config = Get-Content "$PSScriptRoot\..\config\tests.config.json" -Raw | ConvertFrom-Json
        $majorMinorVersion = $PhpVersion.Substring(0, 3)
        if ($config.PSObject.Properties.Name -contains $majorMinorVersion) {
            $settings = $config.$majorMinorVersion
        } else {
            $settings = $config.default
        }

        $settings.workers = $settings.workers.Replace('NumWorkers', $workers)
        return $settings
    }
    end {
    }
}