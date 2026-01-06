Function Get-LibrariesFromConfig {
    <#
    .SYNOPSIS
        Get the Libraries from the config.w32 file
    .PARAMETER PhpVersion
        PhpVersion
    .PARAMETER Extension
        Extension
    .PARAMETER VsVersion
        Visual Studio Version
    .PARAMETER Arch
        Architecture
    .PARAMETER ConfigW32Content
        config.w32 content
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='PHP Version')]
        [string] $PhpVersion,
        [Parameter(Mandatory = $true, Position=1, HelpMessage='Extension')]
        [string] $Extension,
        [Parameter(Mandatory = $true, Position=2, HelpMessage='Visual Studio Version')]
        [string] $VsVersion,
        [Parameter(Mandatory = $true, Position=3, HelpMessage='Architecture')]
        [string] $Arch,
        [Parameter(Mandatory = $true, Position=4, HelpMessage='config.w32 content')]
        [string] $ConfigW32Content
    )
    begin {
        $jsonPath = [System.IO.Path]::Combine($PSScriptRoot, '..\config\vs.json')
    }
    process {
        $jsonDataContent = (Get-File -Url "https://downloads.php.net/~windows/pecl/deps/libmapping.json").Content
        $jsonData = $jsonDataContent | ConvertFrom-Json

        $phpSeries = (Get-File -Url "https://downloads.php.net/~windows/php-sdk/deps/$VsVersion/$Arch").Content.ToLower()

        Function Find-Library {
            param (
                [Parameter(Mandatory=$true, Position=0)]
                [string]$MatchString,
                [Parameter(Mandatory=$true, Position=1)]
                [string[]]$VsVersions
            )
            foreach ($vsVersion in $VsVersions) {
                foreach ($vsVersionData in $JsonData.PSObject.Properties) {
                    if($vsVersionData.Name -eq $VsVersion) {
                        foreach ($archData in $vsVersionData.Value.PSObject.Properties) {
                            if($archData.Name -eq $Arch) {
                                foreach ($libs in $archData.Value.PSObject.Properties) {
                                    if ($libs.Value -match ($MatchString.Replace('*', '.*'))) {
                                        $libs.Name -Match '^(.+?)-\d' | Out-Null
                                        if(!$phpSeries.contains($matches[1].ToLower())) {
                                            $libs.Name -Match '^(.+?-\d)' | Out-Null
                                        }
                                        return $matches[1]
                                    }
                                }
                            }
                        }
                    }
                }
            }
            return $null
        }

        Function Test-Library {
            param (
                [Parameter(Mandatory=$true, Position=0)]
                [string]$library
            )
            if($jsonDataContent.Contains("`"$library-") -or $phpSeries.Contains("`"$library-") -or $jsonDataContent.Contains("`"lib$library-") -or $phpSeries.Contains("`"lib$library-")) {
                return $library
            }
            return $null
        }

        $jsonContent = Get-Content -Path $jsonPath -Raw
        $VsConfig = ConvertFrom-Json -InputObject $jsonContent
        $VsVersions = @($VsVersion)
        $VsVersions += $($VsConfig.vs | Get-Member -MemberType *Property).Name | Where-Object {
            # vs15 and above builds are compatible.
            ($_ -lt $VsVersion -and $_ -ge "vc15")
        }

        $foundItems = @()
        $libraryFilesFound = @()
        [regex]::Matches($ConfigW32Content, 'CHECK_LIB\(["'']([^"'']+)["'']|["'']([^"'']+\.lib)["'']|(\w+\.lib)|(\w+\slib)|(SETUP_\w+)') | ForEach-Object {
            $_.Groups[1].Value.Split(';') + ($_.Groups[2].Value -Split '[^\w\.]') + ($_.Groups[3].Value -Split '[^\w\.]') + ($_.Groups[4].Value) + ($_.Groups[5].Value) | ForEach-Object {
                $libraryFilesFound += $_
            }
        }
        $libraryFilesFound | Select-Object -Unique | ForEach-Object {
            if($_) {
                switch -Wildcard ($_) {
                    SETUP_ZLIB_LIB { $library = "zlib" }
                    SETUP_OPENSSL { $library = "openssl" }
                    SETUP_SQLITE3 { $library = "sqlite" }
                    libeay32.lib { $library = "openssl" }
                    ssleay32.lib { $library = "openssl" }
                    "* lib" { $library = Test-Library $_.Replace(" lib","") }
                    Default { $library = Find-Library $_ $VsVersions }
                }
                if($library -and (-not($foundItems.Contains($library)))) {
                    $foundItems += $library.ToLower()
                }
            }
        }

        # Exceptions
        # Remove libsasl if the extension is mongodb
        if($Extension -eq "mongodb") {
            $foundItems = $foundItems | Where-Object {$_ -notmatch "libsasl.*"}
        }

        # For PHP Version 8.0 and 8.1, replace librabbitmq.openssl3 with librabbitmq.openssl1.1
        if($PhpVersion -match '^8\.[01]') {
            $foundItems = $foundItems | ForEach-Object {
                if($_ -match 'librabbitmq\.openssl3') { $_ -replace 'librabbitmq\.openssl3', 'librabbitmq.openssl1.1' } else { $_ }
            }
        }

        # Custom mappings which are not in config.w32
        if($Extension -eq "memcached" -or $Extension -eq "xlswriter") {
            $foundItems += "zlib"
        }
        if($ConfigW32Content.Contains("boost")) {
            $foundItems += "boost"
        }
        if($Extension -eq "oci8_19" -or $Extension -eq "pdo_oci") {
            $foundItems += "instantclient"
        }
        if($Extension -eq 'ibm_db2' -or $Extension -eq 'pdo_ibm') {
            $foundItems += 'odbc_cli'
        }
        if($Extension -eq 'xmlrpc') {
            $foundItems += 'libiconv'
            $foundItems += 'libxml2'
        }
        if($Extension -eq 'parallel') {
            $foundItems += 'pthreads'
        }
        if($Extension -eq "luasandbox") {
            $foundItems = @("lua-5.1")
        }

        $highestVersions = @{}

        foreach ($item in $foundItems) {
            if ($item -match '^(.*?)-(\d+)$') {
                $libraryName, $version = $matches[1], $matches[2]
                if (-not $highestVersions.ContainsKey($libraryName) -or $highestVersions[$libraryName] -lt $version) {
                    $highestVersions[$libraryName] = $version
                }
            } else {
                $highestVersions[$item] = -1
            }
        }

        $finalItems = @()
        foreach ($library in $highestVersions.Keys) {
            if ($highestVersions[$library] -eq -1) {
                $finalItems += $library
            } else {
                $finalItems += "$library-" + $highestVersions[$library]
            }
        }

        return $finalItems
    }
    end {
    }
}