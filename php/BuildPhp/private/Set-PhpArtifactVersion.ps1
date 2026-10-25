function Set-PhpArtifactVersion {
    <#
    .SYNOPSIS
        Number PHP packages and update external SBOM artifact references without changing archive contents.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $ArtifactsDirectory,
        [Parameter(Mandatory=$true)]
        [string] $PackageVersion
    )

    $version = Get-PhpBuildVersion -PhpVersion $PackageVersion
    if ($version.BuildNumber -eq '') {
        return
    }
    $ArtifactsDirectory = (Resolve-Path -LiteralPath $ArtifactsDirectory).Path

    $versionPattern = '\d+\.\d+\.\d+(?:(?:alpha|beta|RC)\d+|-dev)?(?:-[1-9][0-9]*)?'
    $renames = @(
        foreach ($artifact in Get-ChildItem -LiteralPath $ArtifactsDirectory -Filter 'php-*.zip' -File) {
            if ($artifact.Name -notmatch "^(php-(?:(?:debug|devel|test)-pack-)?)(?<version>$versionPattern)(?<suffix>-.*|\.zip)$") {
                throw "Unsupported PHP archive name: $($artifact.Name)"
            }
            $prefix = $Matches[1]
            $artifactVersion = $Matches.version
            $suffix = $Matches.suffix
            if ($artifactVersion -ne $version.PhpVersion -and $artifactVersion -ne $PackageVersion) {
                throw "Unexpected PHP version $artifactVersion in $($artifact.Name); expected $($version.PhpVersion) or $PackageVersion."
            }
            $name = "$prefix$PackageVersion$suffix"
            $destination = Join-Path $ArtifactsDirectory $name
            if ($artifact.Name -ne $name -and (Test-Path -LiteralPath $destination)) {
                throw "PHP artifact already exists: $destination"
            }
            [PSCustomObject]@{ Artifact = $artifact; Name = $name; Destination = $destination }
        }
    )
    if (-not $renames) {
        throw "No PHP archives found in $ArtifactsDirectory"
    }

    $releaseState = if ($version.PhpVersion -match '^\d+\.\d+\.\d+$') { 'releases' } else { 'qa' }
    foreach ($rename in $renames) {
        $downloadLocation = "https://downloads.php.net/~windows/$releaseState/$($rename.Name)"
        foreach ($format in @('cdx', 'spdx', 'openvex')) {
            $sidecar = "$($rename.Artifact.FullName).$format.json"
            if (-not (Test-Path -LiteralPath $sidecar)) {
                continue
            }
            # ZIP contents and their hashes do not change when the filename changes.
            # Only replace references to this artifact, preserving the source version.
            $contents = (Get-Content -LiteralPath $sidecar -Raw).Replace($rename.Artifact.Name, $rename.Name)
            $contents = $contents.Replace("https://downloads.php.net/~windows/qa/$($rename.Name)", $downloadLocation)
            $destination = "$($rename.Destination).$format.json"
            [System.IO.File]::WriteAllText($destination, $contents, [System.Text.UTF8Encoding]::new($false))
            if ($sidecar -ne $destination) {
                Remove-Item -LiteralPath $sidecar
            }
        }
        if ($rename.Artifact.Name -ne $rename.Name) {
            Rename-Item -LiteralPath $rename.Artifact.FullName -NewName $rename.Name
        }
    }
}
