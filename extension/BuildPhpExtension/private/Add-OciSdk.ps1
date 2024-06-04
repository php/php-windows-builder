Function Add-OciSdk {
    <#
    .SYNOPSIS
        Add sdk for OCI extensions.
    .PARAMETER Config
        The directory to add to PATH.
    #>
    [OutputType()]
    param(
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Configuration for the extension')]
        [PSCustomObject] $Config
    )
    begin {
    }
    process {
        $suffix = if ($Config.arch -eq "x64") {"windows"} else {"nt"}
        $url = "https://download.oracle.com/otn_software/nt/instantclient/instantclient-sdk-$suffix.zip"
        Invoke-WebRequest $url -OutFile "instantclient-sdk.zip"
        Expand-Archive -Path "instantclient-sdk.zip" -DestinationPath "../deps"
        Copy-Item ../deps/instantclient_*/sdk/* -Destination "../deps" -Recurse -Force
    }
    end {
    }
}