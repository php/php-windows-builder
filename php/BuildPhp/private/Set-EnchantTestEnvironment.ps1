function Set-EnchantTestEnvironment {
    <#
    .SYNOPSIS
        Prepare Enchant (hunspell) runtime and dictionaries for tests.
    #>
    [CmdletBinding()]
    param ()
    process {
        $driveRoot = [System.IO.Path]::GetPathRoot((Get-Location).Path)
        $libDir  = Join-Path $driveRoot 'usr\local\lib\enchant-2'
        $dictDir = Join-Path $driveRoot 'usr\local\share\enchant\hunspell'

        New-Item -ItemType Directory -Force -Path $libDir  | Out-Null
        New-Item -ItemType Directory -Force -Path $dictDir | Out-Null

        $depsDir = $env:DEPS_DIR
        if (-not $depsDir) { throw 'DEPS_DIR is not set.' }
        $srcDll = Join-Path $depsDir 'bin\libenchant2_hunspell.dll'
        if (-not (Test-Path -LiteralPath $srcDll)) {
            throw "libenchant2_hunspell.dll not found at $srcDll"
        }
        Copy-Item -LiteralPath $srcDll -Destination $libDir -Force

        Write-Host 'Fetching enchant dicts'
        Push-Location $dictDir
        try {
            $zip = Join-Path $dictDir 'dict.zip'
            $url = 'https://downloads.php.net/~windows/qa/appveyor/ext/enchant/dict.zip'
            Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile $zip
            try {
                Expand-Archive -LiteralPath $zip -DestinationPath $dictDir -Force
            } catch {
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                [System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $dictDir)
            }
            Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue
        } finally {
            Pop-Location
        }
    }
}
