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
            $url = "https://downloads.php.net/~windows/pecl/deps/$_"
            Invoke-WebRequest -Uri $url -OutFile $_ -UseBasicParsing
            Expand-Archive -Path $_ -DestinationPath "..\deps"
            $libName = $_.split('-')[0]
            Rename-Item -Path "..\deps\LICENSE" -NewName "LICENSE.$libName"
        }
    }
    end {
    }
}