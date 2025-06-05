function Invoke-PhpBuild {
    <#
    .SYNOPSIS
        Build PHP.
    .PARAMETER PhpVersion
        PHP Version
    .PARAMETER Arch
        PHP Architecture
    .PARAMETER Ts
        PHP Build Type
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='PHP Version')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $PhpVersion,
        [Parameter(Mandatory = $true, Position=1, HelpMessage='PHP Architecture')]
        [ValidateNotNull()]
        [ValidateSet('x86', 'x64')]
        [string] $Arch,
        [Parameter(Mandatory = $true, Position=2, HelpMessage='PHP Build Type')]
        [ValidateNotNull()]
        [ValidateSet('nts', 'ts')]
        [string] $Ts
    )
    begin {
    }
    process {
        $VsConfig = (Get-VsVersion -PhpVersion $PhpVersion)
        if($null -eq $VsConfig.vs) {
            throw "PHP version $PhpVersion is not supported."
        }

        $currentDirectory = (Get-Location).Path

        $tempDirectory = [System.IO.Path]::GetTempPath()

        $buildDirectory = [System.IO.Path]::Combine($tempDirectory, [System.Guid]::NewGuid().ToString())

        New-Item "$buildDirectory" -ItemType "directory" -Force > $null 2>&1

        Set-Location "$buildDirectory"

        Add-BuildRequirements -PhpVersion $PhpVersion -Arch $Arch

        Copy-Item -Path $PSScriptRoot\..\config -Destination . -Recurse
        $buildPath = "$buildDirectory\config\$($VsConfig.vs)\$Arch\php-$PhpVersion"
        Move-Item "$buildDirectory\php-$PhpVersion-src" $buildPath
        Set-Location "$buildPath"
        New-Item "..\obj" -ItemType "directory" > $null 2>&1
        Copy-Item "..\config.$Ts.bat"

        $task = "$PSScriptRoot\..\runner\task-$Ts.bat"

        & "$buildDirectory\php-sdk\phpsdk-starter.bat" -c $VsConfig.vs -a $Arch -s $VsConfig.toolset -t $task
        if (-not $?) {
            throw "build failed with errorlevel $LastExitCode"
        }

        $artifacts = if ($Ts -eq "ts") {"..\obj\Release_TS\php-*.zip"} else {"..\obj\Release\php-*.zip"}
        New-Item "$currentDirectory\artifacts" -ItemType "directory" -Force > $null 2>&1
        xcopy $artifacts "$currentDirectory\artifacts\*"
        Move-Item "$buildDirectory\php-$PhpVersion-src.zip" "$currentDirectory\artifacts\"

        Set-Location "$currentDirectory"
    }
    end {
    }
}