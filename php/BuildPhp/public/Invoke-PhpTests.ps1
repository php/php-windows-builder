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
        [string] $TestType
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

        $tempDirectory = [System.IO.Path]::GetTempPath()

        $buildDirectory = [System.IO.Path]::Combine($tempDirectory, ("php-" + [System.Guid]::NewGuid().ToString()))

        $testsDirectory = "tests"

        New-Item "$buildDirectory" -ItemType "directory" -Force > $null 2>&1

        New-Item "$buildDirectory\tmp" -ItemType "directory" -Force > $null 2>&1

        Set-Location "$buildDirectory"

        Add-TestRequirements -PhpVersion $PhpVersion -Arch $Arch -Ts $Ts -VsVersion $VsData.vs -TestsDirectory $testsDirectory -ArtifactsDirectory $currentDirectory

        Set-PhpIniForTests -BuildDirectory $buildDirectory -Opcache $Opcache

        $Env:Path = "$buildDirectory\phpbin;$Env:Path"
        $Env:TEST_PHP_EXECUTABLE = "$buildDirectory\phpbin\php.exe"
        $Env:TEST_PHPDBG_EXECUTABLE = "$buildDirectory\phpbin\phpdbg.exe"
        $Env:TEST_PHP_JUNIT = "$buildDirectory\test-$Arch-$Ts-$opcache-$TestType.xml"
        $Env:SKIP_IO_CAPTURE_TESTS = 1
        $Env:NO_INTERACTION = 1
        $Env:REPORT_EXIT_STATUS = 1

        Add-Path -Path "$Env:SystemRoot\System32"

        Set-Location "$testsDirectory"

        Get-TestsList -OutputFile "$TestType-tests-to-run.txt" -Type $TestType

        $settings = Get-TestSettings -PhpVersion $PhpVersion

        if($TestType -eq "ext") {
            Set-MySqlTestEnvironment
            Set-PgSqlTestEnvironment
            Set-OdbcTestEnvironment
            Set-MsSqlTestEnvironment
            Set-FirebirdTestEnvironment
            Set-OpenSslTestEnvironment -PhpBinDirectory "$buildDirectory\phpbin"
            Set-EnchantTestEnvironment
            Set-SnmpTestEnvironment -TestsDirectoryPath "$buildDirectory\$testsDirectory"
        }

        $testResultFile = "$buildDirectory\test-$Arch-$Ts-$Opcache-$TestType.xml"
        $testLogFile = "$buildDirectory\test-$Arch-$Ts-$Opcache-$TestType.log"

        $params = @(
            "-d", "open_basedir=",
            "-d", "output_buffering=0",
            $settings.runner,
            $settings.progress,
            "-g", "FAIL,BORK,WARN,LEAK",
            "-q",
            "--offline",
            "--show-diff",
            "--show-slow", "1000",
            "--set-timeout", "120",
            "--temp-source", "$buildDirectory\tmp",
            "--temp-target", "$buildDirectory\tmp",
            "-r", "$TestType-tests-to-run.txt"
        )

        $workersParam = ""
        if($settings.workers -ne "") {
            $workersParam = $settings.workers
            $params += $workersParam
        }

        $invokeTests = {
            param (
                [string[]] $RunnerParams,
                [string] $LogFilePath
            )
            if(Test-Path $LogFilePath) {
                Remove-Item $LogFilePath -Force
            }

            & $buildDirectory\phpbin\php.exe @RunnerParams 2>&1 | Tee-Object -FilePath $LogFilePath | Out-Host
            return [int]$LASTEXITCODE
        }

        $isWorkerCrash = {
            param (
                [string] $LogFilePath
            )
            return (Test-Path $LogFilePath) -and (Select-String -Path $LogFilePath -Pattern "ERROR:\s+Worker \d+ died unexpectedly" -Quiet)
        }

        $exitCode = & $invokeTests -RunnerParams $params -LogFilePath $testLogFile

        if($exitCode -ne 0 -and $workersParam -ne "") {
            $baseParams = @($params | Where-Object { $_ -ne $workersParam })
            $workerDied = & $isWorkerCrash -LogFilePath $testLogFile
            if($workerDied) {
                Write-Warning "Detected a run-tests worker crash. Retrying once with -j2."
                $retryWithTwoWorkersParams = @($baseParams + "-j2")
                $exitCode = & $invokeTests -RunnerParams $retryWithTwoWorkersParams -LogFilePath $testLogFile

                if($exitCode -ne 0) {
                    $workerDied = & $isWorkerCrash -LogFilePath $testLogFile
                    if($workerDied) {
                        Write-Warning "Detected another worker crash with -j2. Retrying once without parallel workers."
                        $exitCode = & $invokeTests -RunnerParams $baseParams -LogFilePath $testLogFile
                    }
                }
            }
        }

        if(Test-Path $testResultFile) {
            Copy-Item $testResultFile $currentDirectory -Force
        } else {
            Write-Warning "Test results file was not generated: $testResultFile"
        }

        Set-Location "$currentDirectory"

        if($exitCode -ne 0) {
            Write-Warning "PHP tests exited with code $exitCode."
        }
    }
    end {
    }
}
