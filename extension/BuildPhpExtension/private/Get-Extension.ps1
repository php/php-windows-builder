function Get-Extension {
    <#
    .SYNOPSIS
        Get the PHP extension.
    .PARAMETER ExtensionUrl
        Extension URL
    .PARAMETER ExtensionRef
        Extension Reference
    .PARAMETER PhpVersion
        PHP Version
    .PARAMETER BuildDirectory
        Build directory
    .PARAMETER LocalSrc
        Is source local
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $false, Position=0, HelpMessage='Extension URL')]
        [string] $ExtensionUrl = '',
        [Parameter(Mandatory = $false, Position=1, HelpMessage='Extension Reference')]
        [string] $ExtensionRef = '',
        [Parameter(Mandatory = $true, Position=2, HelpMessage='PHP Version')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $PhpVersion,
        [Parameter(Mandatory = $true, Position=3, HelpMessage='Build directory')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $BuildDirectory,
        [Parameter(Mandatory = $true, Position=4, HelpMessage='Is source local')]
        [ValidateNotNull()]
        [bool] $LocalSrc = $false
    )
    begin {
    }
    process {
        if($LocalSrc) {
            $currentDirectory = (Get-Location).Path
            $src = (Resolve-Path $currentDirectory).Path.TrimEnd('\')
            $dst = (Resolve-Path $BuildDirectory).Path.TrimEnd('\')
            if (Get-Command robocopy -ErrorAction SilentlyContinue) {
                & robocopy $src $dst /E /XD $dst "$src\.git" /XJ /MT:16 /R:2 /W:1 /NFL /NDL /NJH /NJS /NP *> $null
                if ($LASTEXITCODE -ge 8) { throw "robocopy failed with exit code $LASTEXITCODE" }
            } else {
                $excludeChild = $null
                if ($dst.StartsWith($src + '\', [StringComparison]::OrdinalIgnoreCase)) {
                    $rel = $dst.Substring($src.Length + 1)
                    $excludeChild = ($rel -split '\\', 2)[0]
                }
                Get-ChildItem -LiteralPath $src -Force |
                    Where-Object { $_.Name -ne '.git' -and ($null -eq $excludeChild -or $_.Name -ne $excludeChild) } |
                    Copy-Item -Destination $dst -Recurse -Force
            }
        } else {
            Add-StepLog "Fetching extension from $ExtensionUrl"
            try {
                if (($null -ne $ExtensionUrl -and $null -ne $ExtensionRef) -and ($ExtensionUrl -ne '' -and $ExtensionRef -ne '')) {
                    Set-Location $BuildDirectory
                    if ($ExtensionUrl -like "*pecl.php.net*") {
                        $extension = Split-Path -Path $ExtensionUrl -Leaf
                        try {
                            Get-File -Url "https://pecl.php.net/get/$extension-$ExtensionRef.tgz" -OutFile "$extension-$ExtensionRef.tgz"
                        } catch {}
                        if(-not(Test-Path "$extension-$ExtensionRef.tgz")) {
                            try {
                                Get-File -Url "https://pecl.php.net/get/$($extension.ToUpper())-$ExtensionRef.tgz" -OutFile "$extension-$ExtensionRef.tgz"
                            } catch {}
                        }
                        & tar -xzf "$extension-$ExtensionRef.tgz" -C $BuildDirectory
                        Copy-Item -Path "$extension-$ExtensionRef\*" -Destination $BuildDirectory -Recurse -Force
                        Remove-Item -Path "$extension-$ExtensionRef" -Recurse -Force
                    } else {
                        if($null -ne $env:AUTH_TOKEN) {
                            $ExtensionUrl = $ExtensionUrl -replace '^https://', "https://${Env:AUTH_TOKEN}@"
                        }
                        git init > $null 2>&1
                        git remote add origin $ExtensionUrl > $null 2>&1
                        git fetch --depth=1 origin $ExtensionRef > $null 2>&1
                        git checkout FETCH_HEAD > $null 2>&1

                        if (Test-Path -LiteralPath (Join-Path (Get-Location).Path '.gitmodules')) {
                            git submodule sync --recursive > $null 2>&1
                            git submodule update --init --recursive --depth 1 > $null 2>&1
                        }
                    }
                }
            } catch {
                Add-BuildLog cross extension "Failed to fetch extension from $ExtensionUrl"
                throw
            }
        }

        $patches = $False
        if($null -ne $extension) {
            if(Test-Path -PATH "$PSScriptRoot\..\patches\${extension}.ps1") {
                if((Get-Content "$PSScriptRoot\..\patches\${extension}.ps1").Contains('config.w32')) {
                    Add-Patches "${extension}.ps1"
                    $patches = $True
                }
            }
            if(Test-Path -PATH "$PSScriptRoot\..\patches\php\${PhpVersion}.ps1") {
                if((Get-Content "$PSScriptRoot\..\patches\php\${PhpVersion}.ps1").Contains('config.w32')) {
                    Add-Patches "php\${PhpVersion}.ps1"
                    $patches = $True
                }
            }
        }

        $configW32 = Get-ChildItem (Get-Location).Path -Recurse -Filter "config.w32" -ErrorAction SilentlyContinue | Select-Object -First 1
        if($null -eq $configW32) {
            if($LocalSrc) {
                throw "No config.w32 found, please make sure you are in the extension source directory and it supports Windows."
            } else {
                throw "No config.w32 found, please check if the extension supports Windows."
            }
        }
        $subDirectory = $configW32.DirectoryName
        if((Get-Location).Path -ne $subDirectory) {
            Copy-Item -Path "${subDirectory}\*" -Destination $BuildDirectory -Recurse -Force
            Remove-Item -Path $subDirectory -Recurse -Force
        }
        $name = Get-ExtensionName

        if(!$patches) {
            Add-Patches "${name}.ps1"
            Add-Patches "php\${PhpVersion}.ps1"
        }
        if(-not($LocalSrc)) {
            Add-BuildLog tick $name "Fetched $name extension"
        }
        return $name
    }
    end {
    }
}