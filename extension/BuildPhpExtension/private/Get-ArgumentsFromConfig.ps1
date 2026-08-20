Function Get-ArgumentsFromConfig {
    <#
    .SYNOPSIS
        Get the Libraries from the config.w32 file
    .PARAMETER Extension
        Extension Name
    .PARAMETER ConfigW32Content
        config.w32 content
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Extension Name')]
        [string] $Extension,
        [Parameter(Mandatory = $true, Position=1, HelpMessage='config.w32 content')]
        [string] $ConfigW32Content
    )
    begin {
        $depsExtensions = Get-Content -Path "$PSScriptRoot\..\config\deps-path-extensions.json" -Raw | ConvertFrom-Json
    }
    process {
        $buildArgPrefix = $null;
        $dashedExtension = $Extension -replace "_", "-"
        if($configW32Content.contains("ARG_ENABLE(`"$dashedExtension`"") -or $configW32Content.contains("ARG_ENABLE('$dashedExtension'")) {
            $buildArgPrefix = "enable"
        } elseif($configW32Content.contains("ARG_WITH(`"$dashedExtension`"") -or $configW32Content.contains("ARG_WITH('$dashedExtension'")) {
            $buildArgPrefix = "with"
        } elseif($configW32Content.contains("ARG_ENABLE(`"$extension`"") -or $configW32Content.contains("ARG_ENABLE('$extension'")) {
            $buildArgPrefix = "enable"
            $dashedExtension = $Extension
        } elseif($configW32Content.contains("ARG_WITH(`"$extension`"") -or $configW32Content.contains("ARG_WITH('$extension'")) {
            $buildArgPrefix = "with"
            $dashedExtension = $Extension
        }

        $arguments = @()

        if($configW32Content.contains('ARG_WITH("boost"')) {
            $arguments += "--with-boost=..\deps\boost"
        }
        if($Extension -eq "bsdiff" -and ($configW32Content.contains('ARG_WITH("bz2"') -or $configW32Content.contains("ARG_WITH('bz2'"))) {
            $arguments += "--with-bz2=..\deps"
        }

        $argValue='';
        if($ConfigW32Content.Contains("PHP_$($Extension.ToUpper())_SHARED")) {
            $argValue = "shared"
        }
        if($depsExtensions -contains $Extension) {
            $argValue = "../deps,shared"
        }
        if($Extension -eq "judy") {
            $argValue = "../deps,shared"
        }

        $arg=''
        if($null -ne $buildArgPrefix) {
            $arg="--$buildArgPrefix-$dashedExtension"
        }
        if($argValue -ne '') {
            $arg="$arg=$argValue"
        }
        $arguments += $arg
        return $arguments
    }
    end {
    }
}
