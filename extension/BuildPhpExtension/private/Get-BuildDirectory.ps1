Function Get-BuildDirectory {
    <#
    .SYNOPSIS
        Get the directory to build the extension.
    #>
    [OutputType()]
    param(
    )
    begin {
    }
    process {
        if ($null -ne $env:BUILD_DIRECTORY) {
            $parentBuildDirectory = $env:BUILD_DIRECTORY
        } else {
            $parentBuildDirectory = [System.IO.Path]::GetTempPath()
        }

        $buildDirectory = [System.Guid]::NewGuid().ToString().substring(0, 8)

        $buildDirectoryPath = [System.IO.Path]::Combine($parentBuildDirectory, $buildDirectory)

        New-Item "$buildDirectoryPath" -ItemType "directory" -Force > $null 2>&1

        return $buildDirectoryPath
    }
    end {
    }
}
