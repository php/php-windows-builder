Function Add-BuildTools {
    <#
    .SYNOPSIS
        Add build tools.
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
        $Config.build_tools | ForEach-Object {
            if($null -eq (Get-Command $_ -ErrorAction SilentlyContinue)) {
                switch ($_)
                {
                    nasm {
                        choco install nasm -y --force
                        Add-Path -Path "$env:ProgramFiles\NASM"
                    }
                    cmake {
                        choco install cmake --installargs 'ADD_CMAKE_TO_PATH=User' -y --force
                    }
                    cargo {
                        choco install rust -y --force
                        Add-Path -Path "$env:USERPROFILE\.cargo\bin"
                    }
                    git {
                        choco install git.install --params "'/GitAndUnixToolsOnPath /WindowsTerminal /NoAutoCrlf'" -y --force
                    }
                    Default {
                        $resultLines = (choco search $_ --limit-output) -split "\`r?\`n"
                        if($resultLines | Where-Object { $_ -match "^$_\|" }) {
                            choco install $_ -y --force
                        }
                    }
                }
            }
        }
    }
    end {
    }
}