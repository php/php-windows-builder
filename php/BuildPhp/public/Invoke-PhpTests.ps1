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
        [string] $Opcache
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

        Get-ChildItem $currentDirectory

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
        $Env:TEST_PHP_JUNIT = "$buildDirectory\test-$Arch-$Ts-$opcache.xml"
        $Env:SKIP_IO_CAPTURE_TESTS = 1

        $Env:OPENSSL_CONF = "$buildDirectory\phpbin\extras\ssl\openssl.cnf"

        $env:MYSQL_TEST_PORT = "3306"
        $Env:MYSQL_TEST_USER = "root"
        $Env:MYSQL_TEST_PASSWD = ""
        $Env:MYSQL_TEST_DB = "test"

        $Env:PDO_MYSQL_TEST_DSN = "mysql:host=localhost;dbname=test"
        $Env:PDO_MYSQL_TEST_USER = "root"
        $Env:PDO_MYSQL_TEST_PASS = ""

        Set-Location "$testsDirectory"

        Get-TestsList -OutputFile "tests-to-run.txt"

        $settings = Get-TestSettings -PhpVersion $PhpVersion

        php `
            $settings.runner `
            $settings.progress `
            "-g" "FAIL,BORK,WARN,LEAK" `
            "-q" `
            "--offline" `
            "--show-diff" `
            "--show-slow" "1000" `
            "--set-timeout" "120" `
            "--temp-source" "$buildDirectory\tmp" `
            "--temp-target" "$buildDirectory\tmp" `
            "-r" "tests-to-run.txt"

        Copy-Item "$buildDirectory\test-$Arch-$Ts-$Opcache.xml" $currentDirectory

        Set-Location "$currentDirectory"
    }
    end {
    }
}