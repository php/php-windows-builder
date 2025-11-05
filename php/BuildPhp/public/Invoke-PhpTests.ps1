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

        $buildDirectory = [System.IO.Path]::Combine($tempDirectory, [System.Guid]::NewGuid().ToString())

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
            Set-OpenSslTestEnvironment
            Set-EnchantTestEnvironment
            Set-SnmpTestEnvironment -TestsDirectoryPath "$buildDirectory\$testsDirectory"
        }

        $params = @(
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

        if($settings.workers -ne "") {
            $params += $settings.workers
        }

        & $buildDirectory\phpbin\php.exe @params

        Copy-Item "$buildDirectory\test-$Arch-$Ts-$Opcache-$TestType.xml" $currentDirectory

        Set-Location "$currentDirectory"
    }
    end {
    }
}