Function Set-XdebugTestEnvironment {
    <#
    .SYNOPSIS
        Set up environment variables for Xdebug extension tests
    .PARAMETER Config
        Extension Configuration
    #>
    [OutputType()]
    param(
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Extension Configuration')]
        [PSCustomObject] $Config
    )
    process {
        $env:XDEBUG_MODE = ""
    }
}
