function Set-PhpIniForTests {
    <#
    .SYNOPSIS
        Set PHP INI for tests.
    .PARAMETER BuildDirectory
        Build directory
    .PARAMETER Opcache
        Opcache
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Build directory')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $BuildDirectory,
        [Parameter(Mandatory = $true, Position=1, HelpMessage='Specify Cache')]
        [ValidateSet('nocache', 'opcache')]
        [string] $Opcache
    )
    begin {
    }
    process {
        $ini = "$BuildDirectory\phpbin\php.ini"
        Copy-Item "$PSScriptRoot\..\config\ini\extensions.ini" $ini
        Add-Content $ini "extension_dir=$BuildDirectory\phpbin\ext"
        if ($Opcache -eq "opcache") {
            New-Item "$BuildDirectory/file_cache" -ItemType "directory" > $null 2>&1
            $opcacheIni = Get-Content "$PSScriptRoot\..\config\ini\opcache-$Arch.ini" -Raw
            $opcacheIni = $opcacheIni.Replace("OPCACHE_ERROR_LOG_PATH", "$BuildDirectory\opcache_error.log")
            $opcacheIni = $opcacheIni.Replace("OPCACHE_FILE_CACHE_PATH", "$BuildDirectory\file_cache")
            Add-Content $ini $opcacheIni
        }
    }
    end {
    }
}