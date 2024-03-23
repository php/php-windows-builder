function Get-Extension {
    <#
    .SYNOPSIS
        Get the PHP extension.
    .PARAMETER ExtensionUrl
        Extension URL
    .PARAMETER ExtensionRef
        Extension Reference
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Extension URL')]
        [string] $ExtensionUrl,
        [Parameter(Mandatory = $true, Position=1, HelpMessage='Extension Reference')]
        [string] $ExtensionRef
    )
    begin {
    }
    process {
        if(
            ($null -eq $ExtensionUrl -or $null -eq $ExtensionRef) -or
            ($ExtensionUrl -eq '' -or $ExtensionRef -eq '')
        ) {
            throw "Both Extension URL and Extension Reference are required."
        }
        if($null -ne $ExtensionUrl -and $null -ne $ExtensionRef) {
            git init > $null 2>&1
            git remote add origin $ExtensionUrl > $null 2>&1
            git fetch --depth=1 origin $ExtensionRef > $null 2>&1
            git checkout FETCH_HEAD > $null 2>&1
        }

        $configW32 = Get-ChildItem (Get-Location).Path -Recurse -Filter "config.w32" -ErrorAction SilentlyContinue
        if($null -eq $configW32) {
            throw "No config.w32 found"
        }
        $currentDirectory = (Get-Location).Path
        $subDirectory = $configW32.DirectoryName
        if((Get-Location).Path -ne $subDirectory) {
            Copy-Item -Path "${subDirectory}\*" -Destination $currentDirectory -Recurse -Force
            Remove-Item -Path $subDirectory -Recurse -Force
        }
        $extensionLine = Get-Content -Path "config.w32" | Select-String -Pattern '\s+(ZEND_)?EXTENSION\(' | Select-Object -First 1
        if($null -eq $extensionLine) {
            throw "No extension found in config.w32"
        }
        return ($extensionLine -replace '.*EXTENSION\(([^,]+),.*', '$1') -replace '["'']', ''
    }
    end {
    }
}