function Get-PhpDeps {
    <#
    .SYNOPSIS
        Fetch specified PHP SDK deps zip packages and extract them to a destination directory.
    .PARAMETER Version
        PHP version series (e.g., 8.3 or master).
    .PARAMETER VsVersion
        Visual Studio toolset version (e.g., vs16, vs17).
    .PARAMETER Arch
        Target architecture: x86 or x64.
    .PARAMETER Destination
        Destination directory to extract the downloaded deps into.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $PhpVersion,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $VsVersion,
        [Parameter(Mandatory=$true)]
        [ValidateSet('x86','x64')]
        [string] $Arch,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Destination
    )

    begin {
        $baseurl = 'https://downloads.php.net/~windows/php-sdk/deps'
    }
    process {
        if (-not (Test-Path -LiteralPath $Destination)) {
            New-Item -ItemType Directory -Force -Path $Destination | Out-Null
        }

        $seriesUrl = "$baseurl/series/packages-$PhpVersion-$VsVersion-$Arch-staging.txt"
        Write-Verbose "Fetching series listing: $seriesUrl"
        $series = Invoke-WebRequest -Uri $seriesUrl -UseBasicParsing -ErrorAction Stop
        $lines = @()
        if ($series -and $series.Content) {
            $lines = $series.Content -split "[\r\n]+" | Where-Object { $_ -and $_.Trim().Length -gt 0 }
        }
        foreach ($line in $lines) {
            Write-Host "Processing package $line"
            $temp = New-TemporaryFile | Rename-Item -NewName { $_.Name + '.zip' } -PassThru
            $url = "$baseurl/$VsVersion/$Arch/$line"
            Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile $temp.FullName -ErrorAction Stop
            try {
                Expand-Archive -LiteralPath $temp.FullName -DestinationPath $Destination -Force
            } catch {
                Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
                [System.IO.Compression.ZipFile]::ExtractToDirectory($temp.FullName, $Destination)
            } finally {
                Remove-Item -LiteralPath $temp.FullName -Force -ErrorAction SilentlyContinue
            }
        }

        $extra = Join-Path $Destination 'openssl.cnf'
        if (Test-Path -LiteralPath $extra) {
            $tdir = Join-Path $Destination 'template\ssl'
            New-Item -ItemType Directory -Force -Path $tdir | Out-Null
            Move-Item -LiteralPath $extra -Destination (Join-Path $tdir 'openssl.cnf') -Force
        }
    }
}
