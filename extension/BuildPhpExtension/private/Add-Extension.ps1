Function Add-Extension {
    <#
    .SYNOPSIS
        Build a PHP extension.
    .PAMAETER Extension
        Extension name.
    .PARAMETER Config
        Configuration for the extension.
    .PARAMETER Prefix
        Prefix for the builds.
    #>
    [OutputType()]
    param(
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Extension name')]
        [PSCustomObject] $Extension,
        [Parameter(Mandatory = $true, Position=1, HelpMessage='Configuration for the extension')]
        [PSCustomObject] $Config,
        [Parameter(Mandatory = $true, Position=2, HelpMessage='Extension build prefix')]
        [string] $Prefix
    )
    begin {
    }
    process {
        # TODO: Replace fetching the extension using the new extension tool
        Invoke-WebRequest -Uri "https://pecl.php.net/get/$Extension" -OutFile "$Extension.tgz"
        $currentDirectory = (Get-Location).Path
        & tar -xzf "$Extension.tgz" -C $currentDirectory
        Set-Location "$Extension-*"
        $bat_content = @()
        $bat_content += ""
        $bat_content += "call phpize 2>&1"
        $bat_content += "call configure --with-php-build=`"..\deps`" $($Config.options) --with-prefix=$Prefix 2>&1"
        $bat_content += "nmake /nologo 2>&1"
        $bat_content += "exit %errorlevel%"
        Set-Content -Encoding "ASCII" -Path $Extension-task.bat -Value $bat_content
        $builder = "$currentDirectory\php-sdk\phpsdk-$($Config.vs_version)-$($Config.Arch).bat"
        $task = (Get-Item -Path "." -Verbose).FullName + "\$Extension-task.bat"
        & $builder -t $task
        Set-Location $currentDirectory
    }
    end {
    }
}