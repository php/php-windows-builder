function Get-PhpSdk {
    <#
    .SYNOPSIS
        Get the PHP SDK.
    .PARAMETER PhpVersion
        PHP Version
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='PHP Version')]
        [ValidateNotNullOrEmpty()]
        [string] $PhpVersion
    )
    begin {
        $configPath = Join-Path $PSScriptRoot '..\config\sdk.json'
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
        $majorMinor = if ($PhpVersion -eq 'master') { 'master' } else { ($PhpVersion -split '\.')[0..1] -join '.' }
        if ($majorMinor -notin $config.PSObject.Properties.Name) {
            throw "No PHP SDK configured for PHP version $PhpVersion."
        }
        $sdkVersion = $config.$majorMinor
        $url = "https://github.com/php/php-sdk-binary-tools/archive/$sdkVersion.zip"
    }
    process {
        Get-File -Url $url -OutFile php-sdk.zip
        Expand-Archive -Path php-sdk.zip -DestinationPath .
        Rename-Item -Path php-sdk-binary-tools-$sdkVersion php-sdk

        # PHP SDK 2.8.4 only recognizes MSVC archive names in its SBOM tool.
        $sbomPath = Join-Path (Get-Location).Path 'php-sdk\bin\phpsdk_sbom.php'
        $sbomScript = Get-Content -LiteralPath $sbomPath -Raw
        [System.IO.File]::WriteAllText($sbomPath,
            $sbomScript.Replace('v[sc]\d+', '(?:v[sc]\d+|clang)'),
            [System.Text.UTF8Encoding]::new($false))
    }
    end {
    }
}
