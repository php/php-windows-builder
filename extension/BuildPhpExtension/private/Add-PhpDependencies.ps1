Function Add-PhpDependencies {
    <#
    .SYNOPSIS
        Add a directory to PATH environment variable.
    .PARAMETER Config
        Configuration for the extension.
    #>
    [OutputType()]
    param(
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Configuration for the extension')]
        [PSCustomObject] $Config
    )
    begin {
    }
    process {
        if($Config.php_libraries.Count -ne 0) {
            Add-StepLog "Adding libraries (core)"
        }
        $phpBaseUrl = 'https://downloads.php.net/~windows/php-sdk/deps'
        $phpTrunkBaseUrl = "https://downloads.php.net/~windows/php-sdk/deps/$($Config.vs_version)/$($Config.arch)"
        $phpSeries = Get-File -Url "$phpBaseUrl/series/packages-$($Config.php_version)-$($Config.vs_version)-$($Config.arch)-staging.txt"
        $phpTrunk = Get-File -Url $phpTrunkBaseUrl
        foreach ($library in $Config.php_libraries) {
            try {
                $matchesFound = $phpSeries.Content | Select-String -Pattern "(^|\n)$library.*"
                if ($matchesFound.Count -eq 0) {
                    foreach ($file in $phpTrunk.Links.Href) {
                        if ($file -match "^$library") {
                            $matchesFound = $file | Select-String -Pattern '.*'
                            break
                        }
                    }
                }
                if ($matchesFound.Count -eq 0) {
                    throw "Failed to find $library"
                }
                $file = $matchesFound.Matches[0].Value.Trim()
                Get-File -Url "$phpBaseUrl/$($Config.vs_version)/$($Config.arch)/$file" -OutFile $library
                Expand-Archive $library "../deps" -Force
                Add-BuildLog tick "$library" "Added $($file -replace '\.zip$')"
            } catch {
                Add-BuildLog cross "$library" "Failed to download $library"
                throw
            }
        }
    }
    end {
    }
}