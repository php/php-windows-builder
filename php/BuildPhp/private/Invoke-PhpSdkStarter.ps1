function Invoke-PhpSdkStarter {
    <#
    .SYNOPSIS
        Invoke phpsdk-starter.bat with the provided build configuration.
    .PARAMETER BuildDirectory
        Build directory containing the PHP SDK.
    .PARAMETER VsConfig
        Visual Studio configuration for the build.
    .PARAMETER Arch
        PHP Architecture
    .PARAMETER Task
        Task script to run through the PHP SDK starter.
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Build directory')]
        [string] $BuildDirectory,
        [Parameter(Mandatory = $true, Position=1, HelpMessage='Visual Studio configuration')]
        [PSCustomObject] $VsConfig,
        [Parameter(Mandatory = $true, Position=2, HelpMessage='PHP Architecture')]
        [ValidateNotNull()]
        [ValidateSet('x86', 'x64')]
        [string] $Arch,
        [Parameter(Mandatory = $true, Position=3, HelpMessage='Task script')]
        [string] $Task
    )
    begin {
    }
    process {
        $process = Start-Process -FilePath "$BuildDirectory\php-sdk\phpsdk-starter.bat" `
                                 -ArgumentList @('-c', $VsConfig.vs, '-a', $Arch, '-s', $VsConfig.toolset, '-t', $Task) `
                                 -NoNewWindow `
                                 -Wait `
                                 -PassThru
        if ($process.ExitCode -ne 0) {
            throw "build failed with errorlevel $($process.ExitCode)"
        }
    }
    end {
    }
}
