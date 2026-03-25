function Get-PhpTestPack {
    <#
    .SYNOPSIS
        Get the PHP source code.
    .PARAMETER PhpVersion
        PHP Version
    .PARAMETER TestsDirectory
        Tests Directory
    .PARAMETER SourceRepository
        php-src repository to source tests from when SourceRef is provided.
    .PARAMETER SourceRef
        Optional branch, tag, or SHA in the custom php-src repository.
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='PHP Version')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $PhpVersion,
        [Parameter(Mandatory = $false, Position=1, HelpMessage='Tests Directory')]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $TestsDirectory,
        [Parameter(Mandatory = $false, Position=2, HelpMessage='php-src repository to source tests from when SourceRef is provided')]
        [string] $SourceRepository = 'php/php-src',
        [Parameter(Mandatory = $false, Position=3, HelpMessage='Optional branch, tag, or SHA in the custom php-src repository')]
        [string] $SourceRef = ''
    )
    begin {
    }
    process {
        Add-Type -Assembly "System.IO.Compression.Filesystem"

        $versionInUrl = $PhpVersion
        $currentDirectory = (Get-Location).Path
        $testsDirectoryPath = Join-Path $currentDirectory $TestsDirectory
        $useCustomSource = -not [string]::IsNullOrWhiteSpace($SourceRef)

        if($useCustomSource) {
            if([string]::IsNullOrWhiteSpace($SourceRepository)) {
                throw "SourceRepository must be provided to source tests from a custom php-src archive."
            }

            $sourceZipFile = ("php-src-tests-{0}-{1}.zip" -f `
                ($SourceRepository -replace '[\\/]', '-'), `
                ($SourceRef -replace '[^0-9A-Za-z._-]', '-'))
            $sourceZipPath = Join-Path $currentDirectory $sourceZipFile
            $extractRoot = Join-Path $currentDirectory ("php-src-tests-" + [System.Guid]::NewGuid().ToString())
            $sourceUrl = "https://api.github.com/repos/$SourceRepository/zipball/$([System.Uri]::EscapeDataString($SourceRef))"
            $headers = @{
                'User-Agent' = 'php-windows-builder'
                'X-GitHub-Api-Version' = '2022-11-28'
            }

            if($env:GITHUB_TOKEN) {
                $headers['Authorization'] = 'Bearer ' + $env:GITHUB_TOKEN
            } else {
                Write-Warning 'GITHUB_TOKEN not set. API rate limits may apply when downloading custom php-src tests.'
            }

            Write-Host "Downloading PHP tests from $SourceRepository@$SourceRef..."
            Invoke-WebRequest -Uri $sourceUrl -Headers $headers -OutFile $sourceZipPath -UseBasicParsing

            New-Item -Path $extractRoot -ItemType "directory" -Force > $null 2>&1
            try {
                try {
                    [System.IO.Compression.ZipFile]::ExtractToDirectory($sourceZipPath, $extractRoot)
                } catch {
                    7z x $sourceZipPath "-o$extractRoot" -y | Out-Null
                }

                $sourceRoots = @(
                    Get-ChildItem -Path $extractRoot -Directory
                )
                if($sourceRoots.Count -ne 1) {
                    throw "Expected a single root directory in custom php-src archive, found $($sourceRoots.Count)."
                }

                Move-Item -Path $sourceRoots[0].FullName -Destination $testsDirectoryPath
            } finally {
                Remove-Item -Path $extractRoot -Recurse -Force -ErrorAction Ignore
            }

            return
        }

        if($PhpVersion -eq 'master') {
            $fallbackBaseUrl = $baseUrl = "https://github.com/shivammathur/php-builder-windows/releases/download/master"
            $versionInUrl = "master"
        } else {
            $releaseState = if ($PhpVersion -match "[a-z]") {"qa"} else {"releases"}
            $baseUrl = "https://downloads.php.net/~windows/$releaseState"
            $fallbackBaseUrl = "https://downloads.php.net/~windows/$releaseState/archives"
        }
        $testZipFile = "php-test-pack-$versionInUrl.zip"
        $testUrl = "$baseUrl/$testZipFile"
        $fallBackUrl = "$fallbackBaseUrl/$testZipFile"

        try {
            Get-File -Url $testUrl -OutFile $testZipFile
        } catch {
            try {
                Get-File -Url $fallBackUrl -OutFile $testZipFile
            } catch {
                throw "Failed to download the test pack for PHP version $PhpVersion."
            }
        }

        $testZipFilePath = Join-Path $currentDirectory $testZipFile

        try {
            [System.IO.Compression.ZipFile]::ExtractToDirectory($testZipFilePath, $testsDirectoryPath)
        } catch {
            7z x $testZipFilePath "-o$testsDirectoryPath" -y | Out-Null
        }
    }
    end {
    }
}
