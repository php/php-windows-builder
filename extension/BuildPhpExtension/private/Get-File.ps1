Function Get-File {
    <#
    .SYNOPSIS
        Downloads a file from a URL with retries and an optional fallback URL.
    .PARAMETER Url
        The primary URL to download the file from.
    .PARAMETER FallbackUrl
        An optional fallback URL to use if the primary URL fails.
    .PARAMETER OutFile
        The output file path where the downloaded content will be saved.
    .PARAMETER Retries
        The number of times to retry the download if it fails. Default is 3.
    .PARAMETER TimeoutSec
        The timeout in seconds for each download attempt. Default is 0 (no timeout).
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Primary URL to download the file from')]
        [ValidateNotNullOrEmpty()]
        [string] $Url,

        [Parameter(Mandatory = $false, Position=1, HelpMessage='Fallback URL to use if the primary URL fails')]
        [string] $FallbackUrl,

        [Parameter(Mandatory = $false, Position=2, HelpMessage='Output file path for the downloaded content')]
        [string] $OutFile = '',

        [Parameter(Mandatory = $false, Position=3, HelpMessage='Number of retries for download attempts')]
        [int] $Retries = 3,

        [Parameter(Mandatory = $false, Position=4, HelpMessage='Timeout in seconds for each download attempt')]
        [int] $TimeoutSec = 0
    )

    for ($i = 0; $i -lt $Retries; $i++) {
        try {
            if($OutFile -ne '') {
                Invoke-WebRequest -Uri $Url -OutFile $OutFile -TimeoutSec $TimeoutSec -UseBasicParsing
            } else {
                Invoke-WebRequest -Uri $Url -TimeoutSec $TimeoutSec -UseBasicParsing
            }
            break;
        } catch {
            if ($i -eq ($Retries - 1)) {
                if($FallbackUrl) {
                    try {
                        if($OutFile -ne '') {
                            Invoke-WebRequest -Uri $FallbackUrl -OutFile $OutFile -TimeoutSec $TimeoutSec -UseBasicParsing
                        } else {
                            Invoke-WebRequest -Uri $FallbackUrl -TimeoutSec $TimeoutSec -UseBasicParsing
                        }
                    } catch {
                        throw "Failed to download the file from $Url and $FallbackUrl - $($_.Exception.Message)"
                    }
                } else {
                    throw "Failed to download the file from $Url - $($_.Exception.Message)"
                }
            }
        }
    }
}
