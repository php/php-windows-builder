Function Invoke-Tests {
    <#
    .SYNOPSIS
        Build the extension
    .PARAMETER Config
        Extension Configuration
    #>
    [OutputType()]
    param(
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Extension Configuration')]
        [PSCustomObject] $Config
    )
    begin {
    }
    process {
        $currentDirectory = (Get-Location).Path
        $php_dir = Join-Path $currentDirectory php-bin
        $env:TEST_PHP_EXECUTABLE = "$php_dir\php.exe"
        $env:REPORT_EXIT_STATUS = 1
        $env:XDEBUG_MODE = ""
        $env:TEMP=$((Get-Item -LiteralPath $Env:TEMP).FullName)
        $env:TMP=$((Get-Item -LiteralPath $Env:TMP).FullName)
        $type='extension'
        if ((Select-String -Path 'config.w32' -Pattern 'ZEND_EXTENSION\(' -Quiet) -eq $true) {
            $type='zend_extension'
        }
        $php_args = @(
            "-n",
            "-d $type=$currentDirectory\$($Config.build_directory)\php_$($Config.name).dll"
        )
        $env:TEST_PHP_ARGS = $php_args -join ' '
        if ($null -eq $env:TEST_RUNNER) {
            $env:TEST_RUNNER = 'run-tests.php'
        } elseif(-not(Test-Path $env:TEST_RUNNER)) {
            throw "Test runner $env:TEST_RUNNER does not exist."
        }
        $test_runner_args = @(
            '-j8',
            '-q',
            '--offline',
            '--show-diff',
            '--show-slow 1000',
            '--set-timeout 120',
            '-g FAIL,XFAIL,BORK,WARN,LEAK,SKIP',
            '--temp-source ' + $env:TEMP,
            '--temp-target ' + $env:TEMP
        )
        $phpExpression = "php $env:TEST_RUNNER " + ($test_runner_args -join ' ')
        chcp 65001
        Write-Output "Running tests... $phpExpression"
        Write-Output "TEST_PHP_ARGS $env:TEST_PHP_ARGS"
        Write-Output "TEST_PHP_EXECUTABLE $env:TEST_PHP_EXECUTABLE"
        Invoke-Expression $phpExpression
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
    }
    end {
    }
}