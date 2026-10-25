$moduleRoot = Split-Path $PSScriptRoot -Parent
foreach ($script in Get-ChildItem "$moduleRoot/private/*.ps1", "$moduleRoot/public/*.ps1") {
    . $script.FullName
}

Describe 'PHP build versions' {
    It 'resolves source <Source> with number <Number> to <Package>' -TestCases @(
        @{ Source = '8.5.12'; Number = ''; Package = '8.5.12'; Base = '8.5.12' },
        @{ Source = '8.5.12'; Number = '1'; Package = '8.5.12-1'; Base = '8.5.12' },
        @{ Source = '8.5.12-1'; Number = ''; Package = '8.5.12-1'; Base = '8.5.12' },
        @{ Source = '8.5.12-1'; Number = '1'; Package = '8.5.12-1'; Base = '8.5.12' },
        @{ Source = '8.6.0RC1'; Number = '2'; Package = '8.6.0RC1-2'; Base = '8.6.0RC1' },
        @{ Source = '8.6.0-dev'; Number = '10'; Package = '8.6.0-dev-10'; Base = '8.6.0-dev' },
        @{ Source = 'master'; Number = ''; Package = 'master'; Base = 'master' }
    ) {
        param($Source, $Number, $Package, $Base)
        $version = Get-PhpBuildVersion -PhpVersion $Source -BuildNumber $Number
        $version.SourceVersion | Should -Be $Source
        $version.PhpVersion | Should -Be $Base
        $version.PackageVersion | Should -Be $Package
    }

    It 'rejects invalid or conflicting number <Number> for <Source>' -TestCases @(
        @{ Source = '8.5.12'; Number = '0' },
        @{ Source = '8.5.12'; Number = '-1' },
        @{ Source = '8.5.12'; Number = '01' },
        @{ Source = '8.5.12'; Number = '1.2' },
        @{ Source = '8.5.12-1'; Number = '2' },
        @{ Source = '8.5.12-0'; Number = '' },
        @{ Source = 'master'; Number = '1' }
    ) {
        param($Source, $Number)
        { Get-PhpBuildVersion -PhpVersion $Source -BuildNumber $Number } | Should -Throw
    }

    It 'uses the base PHP version for historical dependency overrides' {
        Mock Get-File { [PSCustomObject]@{ Content = 'zlib-1.3.2-vs17-x64.zip' } }
        Mock Test-Path { $true }
        Mock Get-Content { '{"8.5":{"maxVersion":"8.5.12","libraries":{"zlib":"1.3.1"}}}' }
        $packages = Get-PhpDepsPackages -PhpVersion '8.5.12-1' -VsVersion vs17 -Arch x64
        $packages.Packages | Should -Contain 'zlib-1.3.1-vs17-x64.zip'
        Assert-MockCalled Get-File -Times 1 -Exactly -ParameterFilter { $Url -like '*/packages-8.5-vs17-x64-staging.txt' }
    }
}

Describe 'Numbered PHP SBOM references' {
    It 'preserves ZIP hashes and source identities while updating <Version> artifact links' -TestCases @(
        @{ Version = '8.5.12'; Destination = 'releases' },
        @{ Version = '8.6.0RC1'; Destination = 'qa' },
        @{ Version = '8.6.0-dev'; Destination = 'qa' }
    ) {
        param($Version, $Destination)
        $directory = Join-Path $TestDrive $Version
        New-Item -ItemType Directory -Path $directory | Out-Null
        $name = "php-$Version-nts-Win32-vs17-x64.zip"
        $artifact = Join-Path $directory $name
        [IO.File]::WriteAllText($artifact, 'unchanged archive bytes')
        $hash = (Get-FileHash $artifact).Hash
        $oldUrl = "https://downloads.php.net/~windows/$Destination/$name"
        $cdx = @{
            metadata = @{ component = @{
                version = $Version; hashes = @(@{ alg = 'SHA-256'; content = $hash })
                externalReferences = @(@{ type = 'distribution'; url = $oldUrl })
                properties = @(
                    @{ name = 'php:artifact-file-name'; value = $name },
                    @{ name = 'php:artifact-download-location'; value = $oldUrl }
                )
            } }
        }
        $spdx = @{
            documentNamespace = "$oldUrl.spdx.json"
            packages = @(@{ SPDXID = 'SPDXRef-PHP'; versionInfo = $Version; packageFileName = $name; downloadLocation = $oldUrl; checksums = @(@{ algorithm = 'SHA256'; checksumValue = $hash }) })
        }
        $cdx | ConvertTo-Json -Depth 20 | Set-Content "$artifact.cdx.json"
        $spdx | ConvertTo-Json -Depth 20 | Set-Content "$artifact.spdx.json"
        '{"statements":[]}' | Set-Content "$artifact.openvex.json"

        Set-PhpArtifactVersion -ArtifactsDirectory $directory -PackageVersion "$Version-1"
        # Already-numbered source archives must also be handled without duplicating the suffix.
        Set-PhpArtifactVersion -ArtifactsDirectory $directory -PackageVersion "$Version-1"

        $newName = "php-$Version-1-nts-Win32-vs17-x64.zip"
        $newArtifact = Join-Path $directory $newName
        $url = "https://downloads.php.net/~windows/$Destination/$newName"
        (Get-FileHash $newArtifact).Hash | Should -Be $hash
        Test-Path $artifact | Should -Be $false
        $cdx = Get-Content "$newArtifact.cdx.json" -Raw | ConvertFrom-Json
        $cdx.metadata.component.version | Should -Be $Version
        $cdx.metadata.component.hashes[0].content | Should -Be $hash
        $cdx.metadata.component.externalReferences[0].url | Should -Be $url
        ($cdx.metadata.component.properties | Where-Object name -eq 'php:artifact-file-name').value | Should -Be $newName
        $spdx = Get-Content "$newArtifact.spdx.json" -Raw | ConvertFrom-Json
        $spdx.documentNamespace | Should -Be "$url.spdx.json"
        $spdx.packages[0].versionInfo | Should -Be $Version
        $spdx.packages[0].downloadLocation | Should -Be $url
        $spdx.packages[0].checksums[0].checksumValue | Should -Be $hash
        Test-Path "$newArtifact.openvex.json" | Should -Be $true
        @(Get-ChildItem $directory -File).Count | Should -Be 4
    }
}
