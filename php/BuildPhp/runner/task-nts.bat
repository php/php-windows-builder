set LDFLAGS="/d2:-AllowCompatibleILVersions" 2>&1
call buildconf.bat 2>&1
if errorlevel 1 exit 1

findstr /c:"--with-toolset=clang" config.nts.bat >nul 2>&1
if errorlevel 1 goto msvc

if defined PHP_CLANG_RESOURCE_DIR (
    set "CFLAGS=%CFLAGS% -resource-dir="%PHP_CLANG_RESOURCE_DIR%""
    set "LDFLAGS=%LDFLAGS% /libpath:"%PHP_CLANG_RESOURCE_DIR%\lib\windows""
)

rem clang-cl PGO: --enable-pgi/--with-pgo add the profile flags via configure, phpsdk_pgo only runs the training workloads.
rem the profiles go into BUILD_DIR, which nmake clean-pgo preserves like the pgd files of the Visual Studio flow.
set "PGO_DIR=%CD%\..\obj\Release"
del /f /q "%PGO_DIR%\*.profraw" "%PGO_DIR%\php.profdata" >nul 2>&1
set "LLVM_PROFILE_FILE=%PGO_DIR%\php-%%p.profraw"
rem init only serves one request, have php-cgi exit right away so its profile is written before the training env shutdown.
set "PHP_FCGI_MAX_REQUESTS=1"
call config.nts.bat 2>&1
if errorlevel 1 exit 2
nmake 2>&1
if errorlevel 1 exit 3
call phpsdk_pgo --init 2>&1
if errorlevel 1 exit 4
rem pgo01org serves 12 requests per scenario (max_runs x 1 url); php-cgi self-exits after the last one and writes its profile.
set "PHP_FCGI_MAX_REQUESTS=12"
call phpsdk_pgo --train --scenario default 2>&1
if errorlevel 1 exit 5
call phpsdk_pgo --train --scenario cache 2>&1
if errorlevel 1 exit 6
llvm-profdata merge -output="%PGO_DIR%\php.profdata" "%PGO_DIR%\*.profraw"
if errorlevel 1 exit 7
nmake clean-pgo 2>&1
if errorlevel 1 exit 8
sed -i "s/enable-pgi/with-pgo/" config.nts.bat 2>&1
if errorlevel 1 exit 9
set "LLVM_PROFILE_FILE="
set "PHP_FCGI_MAX_REQUESTS="
call config.nts.bat 2>&1
if errorlevel 1 exit 10
nmake && nmake snap 2>&1
if errorlevel 1 exit 11
exit /b 0

:msvc
call config.nts.bat 2>&1
if errorlevel 1 exit 2
nmake 2>&1
if errorlevel 1 exit 3
call phpsdk_pgo --init 2>&1
if errorlevel 1 exit 4
call phpsdk_pgo --train --scenario default 2>&1
if errorlevel 1 exit 5
call phpsdk_pgo --train --scenario cache 2>&1
if errorlevel 1 exit 6
nmake clean-pgo 2>&1
if errorlevel 1 exit 7
sed -i "s/enable-pgi/with-pgo/" config.nts.bat 2>&1
if errorlevel 1 exit 8
call config.nts.bat 2>&1
if errorlevel 1 exit 9
nmake && nmake snap 2>&1
if errorlevel 1 exit 10
exit /b 0
