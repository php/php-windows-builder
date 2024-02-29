Function Add-Extensions {
    <#
    .SYNOPSIS
        Add PHP extensions.
    .PARAMETER Config
        Configuration for the extension.
    .PARAMETER Prefix
        Prefix for the builds.
    #>
    [OutputType()]
    param(
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Configuration for the extension')]
        [PSCustomObject] $Config,
        [Parameter(Mandatory = $true, Position=1, HelpMessage='Extension build prefix')]
        [string] $Prefix
    )
    begin {
    }
    process {
        $config.extensions | ForEach-Object {
            Add-Extension -Extension $_ -Config $Config -Prefix $Prefix
        }
    }
    end {
    }
}