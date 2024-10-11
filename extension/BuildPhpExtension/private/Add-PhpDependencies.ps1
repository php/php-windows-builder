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
        $phpSeries = Invoke-WebRequest -Uri "$phpBaseUrl/$($Config.vs_version)/$($Config.arch)"
        foreach ($library in $Config.php_libraries) {
            try {
                $installed = $null
                foreach ($file in $phpSeries.Links.Href) {
                    if ($file -match "^$library") {
                        Invoke-WebRequest "$phpBaseUrl/$($Config.vs_version)/$($Config.arch)/$file" -OutFile $library
                        Expand-Archive $library "../deps"
                        $installed = $file
                        break
                    }
                }
                if (-not $installed) {
                    throw "Failed to download $library"
                }
                $file = $matches.Matches[0].Value.Trim()
                Invoke-WebRequest "$phpBaseUrl/$($Config.vs_version)/$($Config.arch)/$file" -OutFile $library
                Expand-Archive $library "../deps"
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