function Get-PhpSdk {
    <#
    .SYNOPSIS
        Get the PHP SDK.
    #>
    [OutputType()]
    param (
    )
    begin {
        $sdkVersion = "php-sdk-2.8.4"
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
