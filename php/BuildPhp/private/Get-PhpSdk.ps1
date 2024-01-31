function Get-PhpSdk {
    <#
    .SYNOPSIS
        Get the PHP SDK.
    #>
    [OutputType()]
    param (
    )
    begin {
        $url = "https://github.com/php/php-sdk-binary-tools/archive/master.zip"
    }
    process {
        Invoke-WebRequest $url -OutFile php-sdk.zip
        Expand-Archive -Path php-sdk.zip -DestinationPath .
        Rename-Item -Path php-sdk-binary-tools-master php-sdk
    }
    end {
    }
}