function Set-OpenSslTestEnvironment {
    <#
    .SYNOPSIS
        Prepare OpenSSL config directory for tests and unset OPENSSL_CONF.
    .PARAMETER
        PhpBinDirectory
        PHP bin directory
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='PHP bin directory')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $PhpBinDirectory
    )
    process {
        foreach ($dir in @('C:\OpenSSL-Win32','C:\OpenSSL-Win64')) {
            Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
        }

        $opensslDir = if ([System.Environment]::Is64BitOperatingSystem) {
            if ([System.Environment]::Is64BitProcess) {
                'C:\Program Files\Common Files\SSL'
            } else {
                'C:\Program Files (x86)\Common Files\SSL'
            }
        } else {
            'C:\Program Files\Common Files\SSL'
        }

        if ($env:GITHUB_ACTIONS -and $env:GITHUB_ACTIONS.ToString().ToLower() -eq 'true') {
            Remove-Item -LiteralPath $opensslDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        New-Item -ItemType Directory -Force -Path $opensslDir | Out-Null

        if (-not $env:DEPS_DIR) {
            throw 'DEPS_DIR is not set.'
        }
        $source = Join-Path $env:DEPS_DIR 'template\ssl\openssl.cnf'
        if (-not (Test-Path -LiteralPath $source)) {
            throw "openssl.cnf not found at $source"
        }
        Copy-Item -LiteralPath $source -Destination $opensslDir -Force
        $Env:OPENSSL_CONF = "$PhpBinDirectory\extras\ssl\openssl.cnf"
    }
}
