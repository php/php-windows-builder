function Set-SnmpTestEnvironment {
    <#
    .SYNOPSIS
        Configure SNMP test environment: set MIBDIRS, patch snmpd.conf, and start snmpd.
    .PARAMETER TestsDirectoryPath
        Absolute path to the extracted PHP tests directory (use the $testsDirectoryPath from Add-TestRequirements).
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $TestsDirectoryPath
    )
    process {
        if (-not $env:DEPS_DIR) {
            throw 'DEPS_DIR is not set. Ensure dependencies are downloaded before SNMP setup.'
        }

        $env:MIBDIRS = Join-Path $env:DEPS_DIR 'share\mibs'

        $confPath = Join-Path $TestsDirectoryPath 'ext\snmp\tests\snmpd.conf'
        if (-not (Test-Path -LiteralPath $confPath)) {
            throw "snmpd.conf not found at $confPath"
        }

        $forwardTestsRoot = ($TestsDirectoryPath -replace '\\','/')
        $bigTestJs = "$forwardTestsRoot/ext/snmp/tests/bigtest.js"

        $content = Get-Content -LiteralPath $confPath -Raw -Encoding UTF8
        $newLine = "exec HexTest cscript.exe /nologo $bigTestJs"
        $updated = [System.Text.RegularExpressions.Regex]::Replace(
            $content,
            '^exec\s+HexTest\s+.*$',
            [System.Text.RegularExpressions.Regex]::Escape($newLine).Replace('\/','/'),
            [System.Text.RegularExpressions.RegexOptions]::Multiline
        )
        if ($updated -ne $content) {
            Set-Content -LiteralPath $confPath -Value $updated -Encoding UTF8
        }

        $snmpd = Join-Path $env:DEPS_DIR 'bin\snmpd.exe'
        if (-not (Test-Path -LiteralPath $snmpd)) {
            # We have net-snmp builds without snmpd.exe
            Get-File -Url 'https://downloads.php.net/~windows/php-sdk/deps/vs16/x64/net-snmp-5.7.3-3-vs16-x64.zip' -OutFile "net-snmp-5.7.3-3-vs16-x64.zip"
            Expand-Archive -Path "net-snmp-5.7.3-3-vs16-x64.zip" -DestinationPath $env:DEPS_DIR -Force
            if (-not (Test-Path -LiteralPath $snmpd)) {
                throw "snmpd.exe not found at $snmpd"
            }
        }
        if(-not(Test-Path snmpd_running)) {
            Start-Process -FilePath $snmpd -ArgumentList @('-C','-c', $confPath, '-Ln') -WindowStyle Hidden
            Set-Content -Path snmpd_running -Value "running" -Encoding ASCII
        }
    }
}
