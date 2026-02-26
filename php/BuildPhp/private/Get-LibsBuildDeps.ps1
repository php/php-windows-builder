function Get-LibsBuildDeps {
    <#
    .SYNOPSIS
        Download dependencies from GitHub Actions workflow runs.
    .PARAMETER Arch
        Target architecture: x86 or x64.
    .PARAMETER Destination
        Destination directory to extract the downloaded deps into.
    .OUTPUTS
        Array of library names that were downloaded.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('x86','x64')]
        [string] $Arch,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Destination
    )

    $downloadedLibs = @()

    $runIds = @($env:LIBS_BUILD_RUNS -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
    if ($runIds.Count -eq 0) {
        Write-Host 'No run IDs provided in LIBS_BUILD_RUNS'
        return $downloadedLibs
    }

    $headers = @{
        'Accept' = 'application/vnd.github+json'
        'X-GitHub-Api-Version' = '2022-11-28'
        'User-Agent' = 'php-windows-builder'
    }

    if ($env:GITHUB_TOKEN) {
        $headers['Authorization'] = 'Bearer ' + $env:GITHUB_TOKEN
    } else {
        Write-Warning 'GITHUB_TOKEN not set. API rate limits may apply.'
    }

    foreach ($runId in $runIds) {
        Write-Host "Processing workflow run: $runId"
        $url = "https://api.github.com/repos/winlibs/winlib-builder/actions/runs/$runId/artifacts"
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

        if ($response.total_count -eq 0) {
            Write-Warning "No artifacts for run $runId"
            continue
        }

        foreach ($artifact in $response.artifacts) {
            # Filter by architecture
            if ($artifact.name -notmatch $Arch) {
                continue
            }

            Write-Host "Downloading artifact: $($artifact.name)"
            $libName = $artifact.name -replace '-\d.*$', ''
            $downloadedLibs += $libName

            $tempZip = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString() + '.zip')

            try {
                Write-Host "Downloading from: $($artifact.archive_download_url)"
                Invoke-WebRequest -Uri $artifact.archive_download_url -Headers $headers -OutFile $tempZip
                Write-Host "Downloaded to: $tempZip (Size: $((Get-Item $tempZip).Length) bytes)"

                Write-Host "Extracting to: $Destination"
                Expand-Archive -LiteralPath $tempZip -DestinationPath $Destination -Force
                Write-Host "Extracted $($artifact.name) successfully"
            }
            catch {
                Write-Error "Failed to process artifact $($artifact.name): $_"
                throw
            }
            finally {
                Remove-Item -Path $tempZip -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Write-Host "Downloaded libraries from workflow runs: $($downloadedLibs -join ', ')"
    return $downloadedLibs
}
