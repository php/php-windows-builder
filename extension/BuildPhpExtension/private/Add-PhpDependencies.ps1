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
        $phpBaseUrl = 'https://downloads.php.net/~windows/php-sdk/deps'
        $phpSeries = Invoke-WebRequest -Uri "$phpBaseUrl/$($Config.vs_version)/$($Config.arch)"
        $no_matches = @()
        foreach ($library in $Config.php_libraries) {
            $installed = $false
            foreach ($file in $phpSeries.Links.Href) {
                if ($file -match "^$library") {
                    Invoke-WebRequest "$phpBaseUrl/$($Config.vs_version)/$($Config.arch)/$file" -OutFile $library
                    Expand-Archive $library "../deps"
                    $installed = $true
                    break
                }
            }
            if (-not $installed) {
                $no_matches += $library
            }
        }
        if ($no_matches.Count -gt 0) {
            foreach ($library in $no_matches) {
                Write-Output "$library not available"
                exit 1
            }
        }
    }
    end {
    }
}