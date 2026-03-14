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
        [Parameter(Mandatory = $false, Position=0, HelpMessage='PHP Version')]
        [string] $PhpVersion = '',
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
        Set-NetSecurityProtocolType
        $fetchSrc = $True
        if($null -eq $PhpVersion -or $PhpVersion -eq '') {
            $fetchSrc = $False
            $PhpVersion = Get-SourcePhpVersion
        }
        $VsConfig = (Get-VsVersion -PhpVersion $PhpVersion)
        if($null -eq $VsConfig.vs) {
            throw "PHP version $PhpVersion is not supported."
        }

        $currentDirectory = (Get-Location).Path

        $tempDirectory = [System.IO.Path]::GetTempPath()

        $buildDirectory = [System.IO.Path]::Combine($tempDirectory, ("php-" + [System.Guid]::NewGuid().ToString()))

        New-Item "$buildDirectory" -ItemType "directory" -Force > $null 2>&1

        try {
            Set-Location "$buildDirectory"

            Add-BuildRequirements -PhpVersion $PhpVersion -Arch $Arch -FetchSrc:$fetchSrc

            $configDirectory = Join-Path $PSScriptRoot "..\config\$($VsConfig.vs)\$Arch"
            $configBatch = Join-Path $configDirectory "config.$Ts.bat"

            if($fetchSrc) {
                Copy-Item -Path $PSScriptRoot\..\config -Destination . -Recurse
                $buildPath = "$buildDirectory\config\$($VsConfig.vs)\$Arch\php-$PhpVersion"
                $sourcePath = "$buildDirectory\php-$PhpVersion-src"
                Move-Item $sourcePath $buildPath
            } else {
                $buildPath = $currentDirectory
            }

            $buildParent = Split-Path -Path $buildPath -Parent
            $artifactsDirectory = Join-Path $currentDirectory 'artifacts'

            Set-Location "$buildPath"
            New-Item (Join-Path $buildParent 'obj') -ItemType "directory" -Force > $null 2>&1
            Copy-Item -Path $configBatch -Destination (Join-Path $buildPath "config.$Ts.bat") -Force

            if(-not [string]::IsNullOrWhiteSpace($env:LIBS_BUILD_RUNS)) {
                Add-PhpDeps -PhpVersion $PhpVersion -VsVersion $VsConfig.vs -Arch $Arch -Destination (Join-Path $buildParent 'deps')
                $taskTemplate = Join-Path $PSScriptRoot "..\runner\task-$Ts.bat"
            } else {
                $taskTemplate = Join-Path $PSScriptRoot "..\runner\task-$Ts-with-deps.bat"
            }

            $task = [System.IO.Path]::GetFileName($taskTemplate)
            Copy-Item -Path $taskTemplate -Destination $task -Force

            Invoke-PhpSdkStarter -BuildDirectory $buildDirectory -VsConfig $VsConfig -Arch $Arch -Task $task

            $artifacts = if ($Ts -eq "ts") {"..\obj\Release_TS\php-*.zip"} else {"..\obj\Release\php-*.zip"}
            New-Item "$artifactsDirectory" -ItemType "directory" -Force > $null 2>&1
            xcopy $artifacts "$artifactsDirectory\*"
            if($fetchSrc) {
                Move-Item "$buildDirectory\php-$PhpVersion-src.zip" "$artifactsDirectory\"
            }
        } finally {
            Set-Location "$currentDirectory"
        }
    }
    end {
    }
}
