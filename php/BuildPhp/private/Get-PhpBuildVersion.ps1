function Get-PhpBuildVersion {
    <#
    .SYNOPSIS
        Resolve the source version and the version used in package filenames.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $PhpVersion,
        [ValidatePattern('^(?:[1-9][0-9]*)?$')]
        [string] $BuildNumber = ''
    )

    $sourceVersion = $PhpVersion
    $versionPattern = '\d+\.\d+\.\d+(?:(?:alpha|beta|RC)\d+|-dev)?'
    if ($PhpVersion -match "^($versionPattern)-([0-9]+)$") {
        $PhpVersion = $Matches[1]
        $tagBuildNumber = $Matches[2]
        if ($tagBuildNumber -notmatch '^[1-9][0-9]*$') {
            throw "Invalid build number in source version $sourceVersion."
        }
        if ($BuildNumber -ne '' -and $BuildNumber -ne $tagBuildNumber) {
            throw "Build number $BuildNumber conflicts with source version $sourceVersion."
        }
        $BuildNumber = $tagBuildNumber
    }

    if ($BuildNumber -ne '' -and $PhpVersion -notmatch "^$versionPattern$") {
        throw 'A build number requires a complete PHP version, such as 8.5.12.'
    }

    [PSCustomObject]@{
        SourceVersion = $sourceVersion
        PhpVersion = $PhpVersion
        BuildNumber = $BuildNumber
        PackageVersion = if ($BuildNumber -eq '') { $PhpVersion } else { "$PhpVersion-$BuildNumber" }
    }
}
