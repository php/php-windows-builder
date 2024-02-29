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
        [Parameter(Mandatory = $false, Position=0, HelpMessage='Extension URL')]
        [string] $ExtensionUrl,
        [Parameter(Mandatory = $false, Position=1, HelpMessage='Extension Reference')]
        [string] $ExtensionRef
    )
    begin {
    }
    process {
        if(
            ($null -ne $ExtensionUrl -and $null -eq $ExtensionRef) -or
            ($null -ne $ExtensionRef -and $null -eq $ExtensionUrl)
        ) {
            throw "Both Extension URL and Extension Reference are required."
        }
        if($null -ne $ExtensionUrl -and $null -ne $ExtensionRef) {
            git init > $null 2>&1
            git remote add origin $ExtensionUrl > $null 2>&1
            git fetch --depth=1 origin $ExtensionRef > $null 2>&1
            git checkout FETCH_HEAD > $null 2>&1
        }

        # TODO: Use composer.json for the extension name
        $packageXml = Get-ChildItem (Get-Location).Path -Recurse -Filter "package.xml" -ErrorAction SilentlyContinue
        if($null -eq $packageXml) {
            throw "No package.xml found"
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
        $xml = [xml](Get-Content $packageXml.FullName)
        return $xml.package.name
    }
    end {
    }
}