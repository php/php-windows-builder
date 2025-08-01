function Get-PhpBuildDetails {
    <#
    .SYNOPSIS
        Get the PHP build Details.
    .PARAMETER Config
        Extension Configuration
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Configuration for the extension')]
        [PSCustomObject] $Config
    )
    begin {
    }
    process {
        if($Config.php_version -eq 'master' -or $Config.php_version -eq '8.5') {
            $baseUrl = $fallbackBaseUrl = "https://github.com/shivammathur/php-builder-windows/releases/download/master"
            $PhpSemver = 'master'
        } else {
            foreach($releaseState in @("releases", "qa")) {
                $baseUrl = "https://downloads.php.net/~windows/$releaseState"
                $fallbackBaseUrl = "https://downloads.php.net/~windows/$releaseState/archives"
                $releases = Get-File -Url "$baseUrl/releases.json" | ConvertFrom-Json
                $phpSemver = $releases.$($Config.php_version).version
                if($null -eq $phpSemver) {
                    $phpSemver = (Get-File -Url $fallbackBaseUrl).Links |
                            Where-Object { $_.href -match "php-($($Config.php_version).[0-9]+).*" } |
                            ForEach-Object { $matches[1] } |
                            Sort-Object { [System.Version]$_ } -Descending |
                            Select-Object -First 1
                }
                if($null -ne $phpSemver) {
                    break
                }
            }
        }
        return [PSCustomObject]@{
            phpSemver = $phpSemver
            baseUrl = $baseUrl
            fallbackBaseUrl = $fallbackBaseUrl
        }
    }
    end {
    }
}