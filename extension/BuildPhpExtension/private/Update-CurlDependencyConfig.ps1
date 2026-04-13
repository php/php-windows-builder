Function Update-CurlDependencyConfig {
    <#
    .SYNOPSIS
        Add curl brotli/zstd CHECK_LIB calls to config.w32 when required.
    .PARAMETER PhpVersion
        PHP Version
    .PARAMETER ConfigW32Path
        Path to config.w32
    #>
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='PHP Version')]
        [string] $PhpVersion,
        [Parameter(Mandatory = $false, Position=1, HelpMessage='Path to config.w32')]
        [string] $ConfigW32Path = 'config.w32'
    )
    begin {
    }
    process {
        if (-not (Test-Path -LiteralPath $ConfigW32Path -PathType Leaf)) {
            return $false
        }

        if ($PhpVersion -ne 'master') {
            if ($PhpVersion -notmatch '^(\d+\.\d+(?:\.\d+)?)') {
                return $false
            }

            if ([version] $matches[1] -lt [version] '8.4') {
                return $false
            }
        }

        $configLines = Get-Content -Path $ConfigW32Path
        $configW32Content = $configLines -join "`r`n"
        if ($configW32Content -notmatch 'libcurl') {
            return $false
        }

        $curlLibraries = @('brotlidec.lib', 'brotlicommon.lib', 'libzstd.lib')
        $missingLibraries = @($curlLibraries | Where-Object {
            $configW32Content -notmatch ("CHECK_LIB\((['""])" + [regex]::Escape($_) + '\1')
        })
        if ($missingLibraries.Count -eq 0) {
            return $false
        }

        $updatedLines = New-Object 'System.Collections.Generic.List[string]'
        $updated = $false

        foreach ($line in $configLines) {
            if (-not $updated) {
                $negatedPattern = '^(?<indent>\s*)if\s*\(\s*!\s*CHECK_LIB\((?<quote>[''"])(?<lib>[^''"]*nghttp2[^''"]*)\k<quote>(?<signature>\s*,\s*[^)]*)\)(?<suffix>.*)$'
                $negatedMatch = [regex]::Match($line, $negatedPattern)
                if ($negatedMatch.Success) {
                    $indent = $negatedMatch.Groups['indent'].Value
                    $quote = $negatedMatch.Groups['quote'].Value
                    $library = $negatedMatch.Groups['lib'].Value
                    $signature = $negatedMatch.Groups['signature'].Value
                    $suffix = $negatedMatch.Groups['suffix'].Value
                    $continuationIndent = $indent + '    '
                    $updatedLines.Add("${indent}if(!CHECK_LIB($quote$library$quote$signature) ||")
                    for ($i = 0; $i -lt $missingLibraries.Count; $i++) {
                        $lineSuffix = if ($i -eq ($missingLibraries.Count - 1)) { $suffix } else { ' ||' }
                        $updatedLines.Add("${continuationIndent}!CHECK_LIB($quote$($missingLibraries[$i])$quote$signature)$lineSuffix")
                    }
                    $updated = $true
                    continue
                }

                $chainPattern = '^(?<indent>\s*)(?<prefix>&&\s*)?CHECK_LIB\((?<quote>[''"])(?<lib>[^''"]*nghttp2[^''"]*)\k<quote>(?<signature>\s*,\s*[^)]*)\)(?<suffix>.*)$'
                $chainMatch = [regex]::Match($line, $chainPattern)
                if ($chainMatch.Success) {
                    $indent = $chainMatch.Groups['indent'].Value
                    $prefix = $chainMatch.Groups['prefix'].Value
                    $quote = $chainMatch.Groups['quote'].Value
                    $library = $chainMatch.Groups['lib'].Value
                    $signature = $chainMatch.Groups['signature'].Value
                    $suffix = $chainMatch.Groups['suffix'].Value
                    $updatedLines.Add("${indent}${prefix}CHECK_LIB($quote$library$quote$signature)")
                    for ($i = 0; $i -lt $missingLibraries.Count; $i++) {
                        $lineSuffix = if ($i -eq ($missingLibraries.Count - 1)) { $suffix } else { '' }
                        $updatedLines.Add("${indent}&& CHECK_LIB($quote$($missingLibraries[$i])$quote$signature)$lineSuffix")
                    }
                    $updated = $true
                    continue
                }
            }

            $updatedLines.Add($line)
        }

        $updatedContent = $updatedLines -join "`r`n"
        if (-not $updated -or $updatedContent -eq $configW32Content) {
            return $false
        }

        Set-Content -Path $ConfigW32Path -Value $updatedContent -Encoding ASCII
        return $true
    }
    end {
    }
}
