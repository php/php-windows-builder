function Add-PhpComplianceFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $SdkDirectory,
        [Parameter(Mandatory=$true)]
        [string] $SourceDirectory,
        [Parameter(Mandatory=$true)]
        [string] $DepsDirectory,
        [Parameter(Mandatory=$true)]
        [string] $Artifact,
        [string] $SbomMetadata = ''
    )

    $arguments = @('--package', $SourceDirectory, $DepsDirectory, $Artifact)
    if ($SbomMetadata) {
        $arguments += $SbomMetadata
    }

    & (Join-Path $SdkDirectory 'bin\phpsdk_sbom.bat') @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Adding compliance files to $(Split-Path $Artifact -Leaf) failed with errorlevel $LASTEXITCODE"
    }
}
