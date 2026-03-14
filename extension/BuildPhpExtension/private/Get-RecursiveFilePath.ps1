Function Get-RecursiveFilePath {
    <#
    .SYNOPSIS
        Get a file path from a directory, preferring the root file over nested matches.
    .PARAMETER Directory
        Directory to search.
    .PARAMETER FileName
        File name to search for.
    #>
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Directory to search.')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Directory,
        [Parameter(Mandatory = $true, Position=1, HelpMessage='File name to search for.')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $FileName
    )
    begin {
    }
    process {
        if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
            return $null
        }

        $searchRoot = (Resolve-Path -LiteralPath $Directory).Path.TrimEnd('\')
        $rootFile = Join-Path $searchRoot $FileName
        if (Test-Path -LiteralPath $rootFile -PathType Leaf) {
            return $rootFile
        }

        $filePath = Get-ChildItem -LiteralPath $searchRoot -Recurse -Filter $FileName -File -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($null -eq $filePath) {
            return $null
        }

        return (Resolve-Path -LiteralPath $filePath.FullName).Path
    }
    end {
    }
}
