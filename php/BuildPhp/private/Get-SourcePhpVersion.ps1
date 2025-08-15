function Get-SourcePhpVersion {
    <#
    .SYNOPSIS
        Get the PHP version from the source code.
    #>
    [OutputType([string])]
    param (
    )
    begin {
    }
    process {
        $versionFile = "main/php_version.h"
        if (-not (Test-Path -Path $versionFile)) {
            throw "PHP source not found. Please either specify PhpVersion or ensure you are in the PHP source directory."
        }

        $content = Get-Content -Path $versionFile -Raw

        $major = [regex]::Match($content, 'PHP_MAJOR_VERSION\s+(\d+)').Groups[1].Value
        $minor = [regex]::Match($content, 'PHP_MINOR_VERSION\s+(\d+)').Groups[1].Value
        $patch = [regex]::Match($content, 'PHP_RELEASE_VERSION\s+(\d+)').Groups[1].Value

        "$major.$minor.$patch"
    }
    end {
    }
}