function Get-PhpSdk {
    <#
    .SYNOPSIS
        Get the PHP SDK.
    #>
    [OutputType()]
    param (
    )
    begin {
        $sdkVersion = "2.3.0"
        $url = "https://github.com/php/php-sdk-binary-tools/archive/php-sdk-$sdkVersion.zip"
    }
    process {
        Invoke-WebRequest $url -OutFile php-sdk.zip
        Expand-Archive -Path php-sdk.zip -DestinationPath .
        Rename-Item -Path php-sdk-binary-tools-php-sdk-$sdkVersion php-sdk
    }
    end {
    }
}