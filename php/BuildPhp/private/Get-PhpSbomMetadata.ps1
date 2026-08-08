function Get-PhpSbomMetadata {
    <#
    .SYNOPSIS
        Download and return the PHP SBOM metadata path when SBOM generation is enabled.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [AllowEmptyString()]
        [string] $Sbom = '',
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $PhpVersion,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $BuildDirectory
    )

    if($Sbom -ne 'true') {
        return ''
    }

    if($PhpVersion -eq 'master') {
        $sbomVersion = 'master'
    } elseif($PhpVersion -match '(\d+\.\d+)') {
        $sbomVersion = $Matches[1]
    } else {
        throw "Cannot determine SBOM metadata version from PHP version $PhpVersion"
    }

    $sbomMetadata = Join-Path $BuildDirectory "php-$sbomVersion.json"
    Get-File -Url "https://downloads.php.net/~windows/php-sdk/sbom/php-$sbomVersion.json" -OutFile $sbomMetadata
    return $sbomMetadata
}
