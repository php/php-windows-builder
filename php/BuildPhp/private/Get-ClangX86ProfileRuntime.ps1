function Get-ClangX86ProfileRuntime {
    <#
    .SYNOPSIS
        Prepare a Clang resource directory with the x86 PGO runtime.
    #>
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $BuildDirectory
    )

    $compiler = (Get-Command clang-cl.exe).Source
    $resourceDirectory = (& $compiler --print-resource-dir | Out-String).Trim()
    if($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $resourceDirectory -PathType Container)) {
        throw 'Unable to locate the Clang resource directory'
    }

    $runtimeDirectory = Join-Path $BuildDirectory ('clang-resource-' + [guid]::NewGuid().ToString('N'))
    $downloadDirectory = Join-Path $BuildDirectory ('clang-runtime-download-' + [guid]::NewGuid().ToString('N'))
    try {
        Copy-Item -LiteralPath $resourceDirectory -Destination $runtimeDirectory -Recurse
        $profileLibrary = Join-Path $runtimeDirectory 'lib\windows\clang_rt.profile-i386.lib'
        if(Test-Path -LiteralPath $profileLibrary) {
            return $runtimeDirectory
        }

        New-Item -Path $downloadDirectory -ItemType Directory | Out-Null
        $compilerVersion = & $compiler --version | Out-String
        if($LASTEXITCODE -ne 0 -or $compilerVersion -notmatch 'clang version (\d+\.\d+\.\d+)') {
            throw 'Unable to determine the Clang version'
        }
        $version = $Matches[1]
        $installer = Join-Path $downloadDirectory 'llvm-win32.exe'
        Get-File -Url "https://github.com/llvm/llvm-project/releases/download/llvmorg-$version/LLVM-$version-win32.exe" -OutFile $installer
        $resourceVersion = Split-Path $resourceDirectory -Leaf
        $libraryPath = "lib\clang\$resourceVersion\lib\windows\clang_rt.profile-i386.lib"
        $sevenZip = Get-Command 7z.exe -ErrorAction SilentlyContinue
        $extractor = if($sevenZip) { $sevenZip.Source } else { Join-Path $env:ProgramFiles '7-Zip\7z.exe' }
        & $extractor x $installer "-o$downloadDirectory" $libraryPath -y | Out-Null
        if($LASTEXITCODE -ne 0) {
            throw 'Unable to extract the Clang x86 PGO runtime'
        }
        $extractedLibrary = Join-Path $downloadDirectory $libraryPath
        if(-not (Test-Path -LiteralPath $extractedLibrary -PathType Leaf)) {
            throw 'The LLVM x86 package does not contain the PGO runtime'
        }
        Copy-Item -LiteralPath $extractedLibrary -Destination $profileLibrary
        return $runtimeDirectory
    } catch {
        if(Test-Path -LiteralPath $runtimeDirectory) {
            Remove-Item -LiteralPath $runtimeDirectory -Recurse -Force
        }
        throw
    } finally {
        if(Test-Path -LiteralPath $downloadDirectory) {
            Remove-Item -LiteralPath $downloadDirectory -Recurse -Force
        }
    }
}
