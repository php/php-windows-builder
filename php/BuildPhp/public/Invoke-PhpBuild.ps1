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
    .PARAMETER Sbom
        Add SBOM files to binary archives
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
        [string] $Ts,
        [Parameter(Mandatory = $false, Position=3, HelpMessage='Add SBOM files')]
        [bool] $Sbom = $false
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

            if($fetchSrc) {
                Copy-Item -Path $PSScriptRoot\..\config -Destination . -Recurse
                $buildPath = "$buildDirectory\config\$($VsConfig.vs)\$Arch\php-$PhpVersion"
                $sourcePath = "$buildDirectory\php-$PhpVersion-src"
                Move-Item $sourcePath $buildPath
            } else {
                $buildPath = $currentDirectory
            }

            $configBatch = Join-Path $configDirectory "config.$Ts.bat"

            $buildParent = Split-Path -Path $buildPath -Parent
            $depsDirectory = Join-Path $buildParent 'deps'
            $artifactsDirectory = Join-Path $currentDirectory 'artifacts'

            Set-Location "$buildPath"
            New-Item (Join-Path $buildParent 'obj') -ItemType "directory" -Force > $null 2>&1
            Copy-Item -Path $configBatch -Destination (Join-Path $buildPath "config.$Ts.bat") -Force
            Add-PhpDeps -PhpVersion $PhpVersion -VsVersion $VsConfig.vs -Arch $Arch -Destination $depsDirectory

            $sbomMetadata = ''
            if($Sbom) {
                if($PhpVersion -eq 'master') {
                    $sbomVersion = 'master'
                } elseif($PhpVersion -match '(\d+\.\d+)') {
                    $sbomVersion = $Matches[1]
                } else {
                    throw "Cannot determine SBOM metadata version from PHP version $PhpVersion"
                }
                $sbomMetadata = Join-Path $buildDirectory "php-$sbomVersion.json"
                Get-File -Url "https://downloads.php.net/~windows/php-sdk/sbom/php-$sbomVersion.json" -OutFile $sbomMetadata
            }
            $taskTemplate = Join-Path $PSScriptRoot "..\runner\task-$Ts.bat"

            $task = [System.IO.Path]::GetFileName($taskTemplate)
            Copy-Item -Path $taskTemplate -Destination $task -Force

            Invoke-PhpSdkStarter -BuildDirectory $buildDirectory -VsConfig $VsConfig -Arch $Arch -Task $task

            $artifacts = if ($Ts -eq "ts") {"..\obj\Release_TS\php-*.zip"} else {"..\obj\Release\php-*.zip"}
            $binaryArtifacts = @(Get-ChildItem -Path $artifacts -File | Where-Object { $_.Name -notmatch '^php-(debug|devel|test)-pack-' })
            foreach($artifact in $binaryArtifacts) {
                Add-PhpComplianceFiles -SdkDirectory (Join-Path $buildDirectory 'php-sdk') `
                                       -SourceDirectory $buildPath `
                                       -DepsDirectory $depsDirectory `
                                       -Artifact $artifact.FullName `
                                       -SbomMetadata $sbomMetadata
            }

            New-Item "$artifactsDirectory" -ItemType "directory" -Force > $null 2>&1
            xcopy $artifacts "$artifactsDirectory\*"

            if($Sbom) {
                foreach($artifact in $binaryArtifacts) {
                    $artifactPath = Join-Path $artifactsDirectory $artifact.Name
                    & "$buildDirectory\php-sdk\bin\phpsdk_sbom.bat" --export "$artifactPath"
                    if($LASTEXITCODE -ne 0) {
                        throw "SBOM export failed for $($artifact.Name) with errorlevel $LASTEXITCODE"
                    }
                }
            }
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
