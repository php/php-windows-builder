function Get-ExtensionSource {
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
        $ExtensionUrl = '',
        [Parameter(Mandatory = $false, Position=1, HelpMessage='Extension Reference')]
        $ExtensionRef = ''
    )
    begin {
    }
    process {
        if($env:GITHUB_ACTIONS -eq "true") {
            if($null -eq $ExtensionUrl -or $ExtensionUrl -eq '') {
                $ExtensionUrl = "https://github.com/$env:GITHUB_REPOSITORY"
            }
            if($null -eq $ExtensionRef -or $ExtensionRef -eq '') {
                if($env:GITHUB_EVENT_NAME -contains "pull_request") {
                    $ExtensionRef = $env:GITHUB_REF
                } elseif($null -ne $env:GITHUB_REF_NAME) {
                    $ExtensionRef = $env:GITHUB_REF_NAME
                } else {
                    $ExtensionRef = $env:GITHUB_SHA
                }
            }
        } else {
            if($null -eq $ExtensionRef -or $ExtensionRef -eq '') {
                try {
                    if(Test-Path package.xml) {
                        $xml = [xml](Get-Content package.xml)
                        $ExtensionRef = $xml.package.version.release
                    } elseif(Test-Path .git) {
                        $tag = git tag --points-at HEAD | Where-Object { $_ -match '^v?(\d+(\.\d+){0,2})$' } | Select-Object -First 1
                        if($tag) {
                            $ExtensionRef = $tag
                        } else {
                            $ExtensionRef = (git rev-parse --abbrev-ref HEAD) -replace 'origin/', ''
                        }
                    } else {
                        $ExtensionRef = 'local'
                    }
                } catch {
                    $ExtensionRef = 'local'
                }
            }
        }
        return [PSCustomObject]@{
            url = $ExtensionUrl;
            ref = $ExtensionRef
            local = ($null -eq $ExtensionUrl -or $ExtensionUrl -eq '')
        }
    }
    end {
    }
}