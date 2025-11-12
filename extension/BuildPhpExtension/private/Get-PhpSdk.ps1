function Get-PhpSdk {
    <#
    .SYNOPSIS
        Get the PHP SDK.
    #>
    [OutputType()]
    param (
    )
    begin {
        $sdkVersion = "php-sdk-2.6.0"
        $url = "https://github.com/php/php-sdk-binary-tools/archive/$sdkVersion.zip"
    }
    process {
        Add-StepLog "Adding PHP SDK"
        try
        {
            Add-Type -Assembly "System.IO.Compression.Filesystem"

            Get-File -Url $url -OutFile php-sdk.zip
            $currentDirectory = (Get-Location).Path
            $sdkZipFilePath = Join-Path $currentDirectory php-sdk.zip
            [System.IO.Compression.ZipFile]::ExtractToDirectory($sdkZipFilePath, $currentDirectory)
            Rename-Item -Path php-sdk-binary-tools-$sdkVersion php-sdk

            $sdkDirectoryPath = Join-Path $currentDirectory php-sdk
            $sdkBinDirectoryPath = Join-Path $sdkDirectoryPath bin
            $sdkMsys2DirectoryPath = Join-Path $sdkDirectoryPath msys2
            Add-Path -PathItem $sdkBinDirectoryPath
            Add-Path -PathItem $sdkMsys2DirectoryPath
            Add-BuildLog tick "PHP SDK" "PHP SDK Added"
        } catch {
            Add-BuildLog cross "PHP SDK" "Failed to fetch PHP SDK"
            throw
        }
    }
    end {
    }
}