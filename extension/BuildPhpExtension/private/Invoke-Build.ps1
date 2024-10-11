Function Invoke-Build {
    <#
    .SYNOPSIS
        Build the extension
    .PARAMETER Config
        Extension Configuration
    #>
    [OutputType()]
    param(
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Extension Configuration')]
        [PSCustomObject] $Config
    )
    begin {
    }
    process {
        Add-StepLog "Building $($Config.name) extension"
        try {
            Set-GAGroup start
            $bat_content = @()
            $bat_content += ""
            $bat_content += "call phpize 2>&1"
            $bat_content += "call configure --with-php-build=`"..\deps`" $($Config.options) --with-mp=`"disable`" --enable-debug-pack 2>&1"
            $bat_content += "nmake /nologo 2>&1"
            $bat_content += "exit %errorlevel%"
            Set-Content -Encoding "ASCII" -Path task.bat -Value $bat_content

            $builder = "php-sdk\phpsdk-$($Config.vs_version)-$($Config.Arch).bat"
            $task = (Get-Item -Path "." -Verbose).FullName + '\task.bat'
            $suffix = "php_" + (@(
                $Config.name,
                $Config.ref,
                $Config.php_version,
                $Config.ts,
                $Config.vs_version,
                $Config.arch
            ) -join "-")
            & $builder -s $Config.vs_toolset -t $task | Tee-Object -FilePath "build-$suffix.txt"
            Set-GAGroup end
            Add-BuildLog tick $Config.name "Extension $($Config.name) built successfully"
        } catch {
            Add-BuildLog cross $Config.name "Failed to build"
            throw
        }
    }
    end {
    }
}