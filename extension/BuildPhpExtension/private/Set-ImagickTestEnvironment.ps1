Function Set-ImagickTestEnvironment {
    <#
    .SYNOPSIS
        Set up environment variables for Imagick extension tests
    .PARAMETER Config
        Extension Configuration
    #>
    [OutputType()]
    param(
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Extension Configuration')]
        [PSCustomObject] $Config
    )
    process {
        $currentDirectory = (Get-Location).Path
        $env:MAGICK_CONFIGURE_PATH = "$currentDirectory\..\deps\bin"
    }
}
