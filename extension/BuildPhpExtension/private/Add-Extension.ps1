Function Add-Extension {
    <#
    .SYNOPSIS
        Build a PHP extension.
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
        # TODO: Replace fetching the extension using the new extension tool
        Invoke-WebRequest -Uri "https://pecl.php.net/get/$($Config.name)" -OutFile "$($Config.name).tgz"
        $currentDirectory = (Get-Location).Path
        Expand-Archive "$($Config.name).tgz" -DestinationPath $currentDirectory
        Set-Location "$($Config.name)-*"
        & phpize
        .\configure.bat --with-php-build=..\..\deps $Config.options --with-prefix=$Prefix
        & nmake
        & nmake install
        Set-Location $currentDirectory
    }
    end {
    }
}