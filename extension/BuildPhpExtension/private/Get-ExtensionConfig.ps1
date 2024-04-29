Function Get-ExtensionConfig {
    <#
    .SYNOPSIS
        Get the configuration for the extension.
    .PARAMETER Extension
        Extension Name
    .PARAMETER ExtensionRef
        Extension Reference
    .PARAMETER PhpVersion
        PHP Version
    .PARAMETER Arch
        Extension Architecture
    .PARAMETER Ts
        Extension Thread Safety
    .PARAMETER VsVersion
        Visual Studio version
    #>
    [OutputType()]
    param(
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Extension Name')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Extension,
        [Parameter(Mandatory = $true, Position=1, HelpMessage='Extension Ref')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $ExtensionRef,
        [Parameter(Mandatory = $true, Position=2, HelpMessage='PHP Version')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $PhpVersion,
        [Parameter(Mandatory = $true, Position=3, HelpMessage='Extension Architecture')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Arch,
        [Parameter(Mandatory = $true, Position=4, HelpMessage='Extension Thread Safety')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Ts,
        [Parameter(Mandatory = $true, Position=5, HelpMessage='Visual Studio version')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $VsVersion
    )
    begin {
    }
    process {
        if(-not(Test-Path composer.json))
        {
            if(Test-Path $PSScriptRoot\..\config\stubs\$Extension.composer.json) {
                Copy-Item $PSScriptRoot\..\config\stubs\$Extension.composer.json composer.json
            }
        }
        $ref = $ExtensionRef
        if ($ref -match 'refs/pull/(\d+)/merge') {
            $ref = $Matches[1]
        }
        $config = [PSCustomObject]@{
            name = $Extension
            ref = $ref
            php_version = $PhpVersion
            arch = $Arch
            ts = $Ts
            vs_version = $VsVersion
            options = @()
            php_libraries = @()
            extension_libraries = @()
            extensions = @()
            docs = @()
            build_directory = ""
        }
        $composerJson = $null
        if(Test-Path composer.json) {
            $composerJson = Get-Content composer.json -Raw | ConvertFrom-Json
        }
        if($null -eq $composerJson -or $null -eq $composerJson."php-ext") {
            if (Test-Path $PSScriptRoot\..\config\stubs\$Extension.composer.json) {
                Copy-Item $PSScriptRoot\..\config\stubs\$Extension.composer.json composer.json
            }
        } else {
            $composerJson."php-ext"."configure-options" | ForEach-Object {
                $config.options += "--$( $_.name )"
            }
        }
        $config.options = $config.options -join " "

        if($null -ne $env:CONFIGURE_ARGS -and -not([string]::IsNullOrWhiteSpace($env:CONFIGURE_ARGS))) {
            $config.options += " $env:CONFIGURE_ARGS"
        }

        $Libraries = @()
        if($null -ne $env:LIBRARIES -and -not([string]::IsNullOrWhiteSpace($env:LIBRARIES))) {
            $Libraries = ($env:LIBRARIES -replace ' ', '') -split ','
        }

        if($null -ne $composerJson) {
            $composerJson."require" | ForEach-Object {
                $_.PSObject.Properties | ForEach-Object {
                    if($_.Name -match "ext-") {
                        $extension = $_.Name
                        if($_.Value -match "\d+\.\d+.*") {
                            $extension += "-$($_.Value)"
                        }
                        $config.extensions += $extension
                    } elseif(-not($_.Name -match "php")) {
                        # If using the stub composer.json
                        $Libraries += $_.Name
                    }
                }
            }
        }

        if($Libraries.Count -gt 0) {
            $phpSeries = (Invoke-WebRequest -Uri "https://downloads.php.net/~windows/php-sdk/deps/series/packages-$PhpVersion-$VsVersion-$Arch-staging.txt").Content
            $extensionSeries = Invoke-WebRequest -Uri "https://downloads.php.net/~windows/pecl/deps"
            $extensionArchivesSeries = Invoke-WebRequest -Uri "https://downloads.php.net/~windows/pecl/deps/archives"
        }
        $Libraries | ForEach-Object {
            if($null -ne $_ -and -not([string]::IsNullOrWhiteSpace($_))) {
                if ($phpSeries.Contains($_) -and -not($config.php_libraries.Contains($_))) {
                    $config.php_libraries += $_
                } elseif (($extensionSeries.Content + $extensionArchivesSeries.Content).ToLower().Contains($_.ToLower()) -and -not($config.extension_libraries.Contains($_))) {
                    $lib = Get-PeclLibraryZip -Library $_ -PhpVersion $PhpVersion -VsVersion $VsVersion -Arch $Arch -ExtensionSeries $extensionSeries
                    if($null -ne $lib) {
                        $config.extension_libraries += $lib
                    } else {
                        $lib = Get-PeclLibraryZip -Library $_ -PhpVersion $PhpVersion -VsVersion $VsVersion -Arch $Arch -ExtensionSeries $extensionArchivesSeries
                        if($null -ne $lib) {
                            $config.extension_libraries += $lib
                        } else {
                            throw "Library $_ not found for the PHP version $PhpVersion and Visual Studio version $VsVersion"
                        }
                    }
                } else {
                    throw "Library $_ not found for the PHP version $PhpVersion and Visual Studio version $VsVersion"
                }
            }
        }

        # TODO: This should be implemented using composer.json once implemented
        $packageXml = Get-ChildItem (Get-Location).Path -Recurse -Filter "package.xml" -ErrorAction SilentlyContinue
        if($null -ne $packageXml) {
            $xml = [xml](Get-Content $packageXml.FullName)
            $config.docs = $xml.SelectNodes("//*[@role='doc']") | ForEach-Object {
                $path = $_.name
                $current = $_.ParentNode
                while ($null -ne $current -and $current.NodeType -eq "Element" -and $current.get_name() -eq "dir") {
                    $path = $current.name + '/' + $path
                    $current = $current.ParentNode
                }
                if ($path.StartsWith("/")) {
                    $path = $path.TrimStart("/")
                }
                $path -replace "/", "\"
            }
        }

        $config.build_directory = if ($Arch -eq "x64") { "x64\" } else { "" }
        $config.build_directory += "Release"
        if ($Ts -eq "ts") { $config.build_directory += "_TS" }
        return $config
    }
    end {
    }
}