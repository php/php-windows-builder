Function Add-ExtensionDependencies {
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
        $Config.extension_libraries | ForEach-Object {
            $outputZip = "$_-$($Config.vs_version)-$($Config.arch).zip"
            $url = "https://downloads.php.net/~windows/pecl/deps/$outputZip"
            Invoke-WebRequest -Uri $url -OutFile $outputZip -UseBasicParsing
            Expand-Archive -Path $outputZip -DestinationPath "..\deps"
            Rename-Item -Path "..\deps\LICENSE" -NewName "..\deps\LICENSE.$_"
        }
    }
    end {
    }
}