function Invoke-CompatRunTestsPatch {
    <#
    .SYNOPSIS
        Apply a compatibility patch file to run-tests.php.
    .PARAMETER Path
        Path to the run-tests.php file.
    .PARAMETER PatchPath
        Path to the compatibility patch file.
    #>
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Path to run-tests.php')]
        [ValidateNotNull()]
        [string] $Path,
        [Parameter(Mandatory = $true, Position=1, HelpMessage='Path to compatibility patch file')]
        [ValidateNotNull()]
        [string] $PatchPath
    )
    begin {
        function Get-PatchExecutable {
            $gitCommand = Get-Command git -ErrorAction SilentlyContinue
            if ($null -eq $gitCommand) {
                return $null
            }

            $gitDirectory = Split-Path -Path $gitCommand.Source -Parent
            $candidateRoots = @(
                (Split-Path -Path $gitDirectory -Parent),
                (Split-Path -Path (Split-Path -Path $gitDirectory -Parent) -Parent)
            )

            foreach ($gitRoot in $candidateRoots) {
                if ([string]::IsNullOrWhiteSpace($gitRoot)) {
                    continue
                }

                $gitPatch = Join-Path $gitRoot 'usr\bin\patch.exe'
                if (Test-Path -Path $gitPatch) {
                    return $gitPatch
                }
            }

            return $null
        }
    }
    process {
        $patchExecutable = Get-PatchExecutable
        if ($null -eq $patchExecutable) {
            return $false
        }

        $targetDirectory = Split-Path -Path $Path -Parent
        $targetFileName = Split-Path -Path $Path -Leaf

        & $patchExecutable -N -s -d $targetDirectory -i $PatchPath
        $exitCode = $LASTEXITCODE

        $rejectFile = Join-Path $targetDirectory "$targetFileName.rej"
        $originalFile = Join-Path $targetDirectory "$targetFileName.orig"
        if (Test-Path -Path $rejectFile) {
            Remove-Item -Path $rejectFile -Force
        }
        if (Test-Path -Path $originalFile) {
            Remove-Item -Path $originalFile -Force
        }

        return $exitCode -eq 0
    }
    end {
    }
}
