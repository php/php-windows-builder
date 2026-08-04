function Invoke-PhpTests {
    <#
    .SYNOPSIS
        Test PHP Build.
    .PARAMETER PhpVersion
        PHP Version
    .PARAMETER Arch
        PHP Architecture
    .PARAMETER Ts
        PHP Build Type
    .PARAMETER Opcache
        Specify Cache
    .PARAMETER TestType
        Test Type
    .PARAMETER SourceRepository
        php-src repository to source tests from when SourceRef is provided.
    .PARAMETER SourceRef
        Optional branch, tag, or SHA in the custom php-src repository.
    .PARAMETER TestDirectories
        Optional test directories to run instead of the configured test list.
    .PARAMETER FailOnError
        Fail when run-tests.php returns a non-zero exit code.
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='PHP Version')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $PhpVersion,
        [Parameter(Mandatory = $true, Position=1, HelpMessage='PHP Architecture')]
        [ValidateNotNull()]
        [ValidateSet('x86', 'x64')]
        [string] $Arch,
        [Parameter(Mandatory = $true, Position=2, HelpMessage='PHP Build Type')]
        [ValidateNotNull()]
        [ValidateSet('nts', 'ts')]
        [string] $Ts,
        [Parameter(Mandatory = $true, Position=3, HelpMessage='Specify Cache')]
        [ValidateSet('nocache', 'opcache')]
        [string] $Opcache,
        [Parameter(Mandatory = $true, Position=4, HelpMessage='Test Type')]
        [ValidateSet('ext', 'php')]
        [string] $TestType,
        [Parameter(Mandatory = $false, Position=5, HelpMessage='php-src repository to source tests from when SourceRef is provided')]
        [string] $SourceRepository = 'php/php-src',
        [Parameter(Mandatory = $false, Position=6, HelpMessage='Optional branch, tag, or SHA in the custom php-src repository')]
        [string] $SourceRef = '',
        [Parameter(Mandatory = $false, Position=7, HelpMessage='Optional test directories')]
        [string[]] $TestDirectories = @(),
        [Parameter(Mandatory = $false, Position=8, HelpMessage='Fail on test errors')]
        [switch] $FailOnError
    )
    begin {
    }
    process {
        Set-NetSecurityProtocolType
        $VsData = (Get-VsVersion -PhpVersion $PhpVersion)
        if($null -eq $VsData.vs) {
            throw "PHP version $PhpVersion is not supported."
        }

        $currentDirectory = (Get-Location).Path

        $tempDirectory = if ([string]::IsNullOrWhiteSpace($env:SystemDrive)) {
            [System.IO.Path]::GetTempPath()
        } else {
            "$($env:SystemDrive)\"
        }

        $buildDirectory = Join-Path $tempDirectory ("php-" + [System.Guid]::NewGuid().ToString())
        $tempDirectory = Join-Path $tempDirectory 'tests_tmp'

        $testsDirectory = "tests"

        New-Item "$buildDirectory" -ItemType "directory" -Force > $null 2>&1

        New-Item "$tempDirectory" -ItemType "directory" -Force > $null 2>&1

        Set-Location "$buildDirectory"

        $testSetup = Add-TestRequirements -PhpVersion $PhpVersion `
                                          -Arch $Arch `
                                          -Ts $Ts `
                                          -VsVersion $VsData.vs `
                                          -TestsDirectory $testsDirectory `
                                          -ArtifactsDirectory $currentDirectory `
                                          -SourceRepository $SourceRepository `
                                          -SourceRef $SourceRef
        Remove-Item Env:LIBS_BUILD_RUNS -ErrorAction SilentlyContinue

        Set-PhpIniForTests -BuildDirectory $buildDirectory -Arch $Arch -Opcache $Opcache -TestType $TestType

        $Env:Path = "$buildDirectory\phpbin;$Env:Path"
        $Env:TEST_PHP_EXECUTABLE = "$buildDirectory\phpbin\php.exe"
        $Env:TEST_PHPDBG_EXECUTABLE = "$buildDirectory\phpbin\phpdbg.exe"
        $Env:TEST_PHP_JUNIT = "$buildDirectory\test-$Arch-$Ts-$opcache-$TestType.xml"
        $Env:SKIP_IO_CAPTURE_TESTS = 1
        $Env:NO_INTERACTION = 1
        $Env:REPORT_EXIT_STATUS = 1

        Add-Path -Path "$Env:SystemRoot\System32"

        Set-Location "$testsDirectory"

        Get-TestsList -OutputFile "$TestType-tests-to-run.txt" -Type $TestType -TestDirectories $TestDirectories

        $settings = Get-TestSettings -PhpVersion $PhpVersion

        if($TestType -eq "ext") {
            Set-PhpExtTestEnvironment -TestDirectories $TestDirectories `
                                      -BuildDirectory $buildDirectory `
                                      -TestsDirectory $testsDirectory `
                                      -Arch $Arch
        }

        $testTimeout = if ($TestType -eq 'ext') { '300' } else { '120' }

        $testResultFile = "$buildDirectory\test-$Arch-$Ts-$Opcache-$TestType.xml"
        $testLogFile = "$buildDirectory\test-$Arch-$Ts-$Opcache-$TestType.log"

        $params = @(
            "-n",
            "-d", "open_basedir=",
            "-d", "output_buffering=0",
            $settings.runner,
            "-p", "$buildDirectory\phpbin\php.exe",
            "-n",
            "-c", "$buildDirectory\phpbin\php-test.ini",
            $settings.progress,
            "-g", "FAIL,BORK,WARN,LEAK",
            "-q",
            "--offline",
            "--show-diff",
            "--show-slow", "1000",
            "--set-timeout", $testTimeout,
            "--temp-source", $tempDirectory,
            "--temp-target", $tempDirectory,
            "-r", "$TestType-tests-to-run.txt"
        )

        $compatPatchApplied = $true
        if ($null -ne $testSetup) {
            foreach ($setupOutput in @($testSetup)) {
                if ($setupOutput -and $setupOutput.PSObject.Properties.Name -contains 'CompatPatchApplied') {
                    $compatPatchApplied = [bool]$setupOutput.CompatPatchApplied
                }
            }
        }

        $workers = $settings.workers
        if($workers -ne "" -and -not $compatPatchApplied) {
            $workers = "-j2"
        }

        if($workers -ne "") {
            $params += $workers
        }

        if(Test-Path $testLogFile) {
            Remove-Item $testLogFile -Force
        }

        & $buildDirectory\phpbin\php.exe @params 2>&1 | Tee-Object -FilePath $testLogFile | Out-Host
        $testExitCode = $LASTEXITCODE

        if(Test-Path $testResultFile) {
            Copy-Item $testResultFile $currentDirectory -Force
        } else {
            Write-Warning "Test results file was not generated: $testResultFile"
        }

        if(Test-Path $testLogFile) {
            Copy-Item $testLogFile $currentDirectory -Force
        }

        Set-Location "$currentDirectory"

        if($FailOnError -and $testExitCode -ne 0) {
            throw "PHP tests failed for $Arch-$Ts-$Opcache-$TestType with exit code $testExitCode"
        }
    }
    end {
    }
}
