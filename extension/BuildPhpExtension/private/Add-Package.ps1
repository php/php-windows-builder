function Add-Package {
    <#
    .SYNOPSIS
        Create a package for the extension.
    .PARAMETER Config
        Extension Configuration
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Extension Configuration')]
        [PSCustomObject] $Config
    )
    begin {
    }
    process {
        $currentDirectory = (Get-Location).Path
        New-Item -Path $currentDirectory\artifacts -ItemType Directory -Force | Out-Null
        Get-ChildItem -Path ..\deps -Recurse -Filter "LICENSE*" | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination artifacts -Force
        }
        if(Test-Path -Path LICENSE) {
            Copy-Item -Path LICENSE -Destination artifacts -Force
        }
        if(Test-Path -Path COPYRIGHT) {
            Copy-Item -Path COPYRIGHT -Destination artifacts -Force
        }
        if(Test-Path -Path COPYING) {
            Copy-Item -Path COPYING -Destination artifacts -Force
        }
        $Config.docs | ForEach-Object {
            $directoryPath = [System.IO.Path]::GetDirectoryName($_)
            $targetDir = Join-Path -Path artifacts -ChildPath $directoryPath
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            Copy-Item -Path $_ -Destination $targetDir -Force
        }
        Get-ChildItem -Path $Config.build_directory -Recurse -Filter "*.dll" | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination artifacts -Force
        }
        Get-ChildItem -Path "artifacts\*.dll" | ForEach-Object {
            $pdbFilePath = Join-Path -Path $Config.build_directory -ChildPath ($_.BaseName + ".pdb")
            if (Test-Path -Path $pdbFilePath) {
                Copy-Item -Path $pdbFilePath -Destination artifacts -Force
            }
        }

        Set-Location $currentDirectory\artifacts
        if(Test-Path -Path "vc140.pdb") {
            Remove-Item -Path "vc140.pdb" -Force
        }
        $artifact = "php_$($Config.name)-$($Config.ref)-$($Config.php_version)-$($Config.ts)-$($Config.vs_version)-$($Config.arch)"
        7z a -sdel "$artifact.zip" *

        Set-Location $currentDirectory
        New-Item -Path $currentDirectory\artifacts\logs -ItemType Directory -Force | Out-Null
        Copy-Item -Path build-*.txt -Destination artifacts\logs\ -Force
        Set-Location $currentDirectory\artifacts\logs
        7z a -sdel "$artifact.zip" *
    }
    end {
    }
}