set LDFLAGS="/d2:-AllowCompatibleILVersions" 2>&1
call phpsdk_deps.bat -s staging -u 2>&1
if errorlevel 1 exit 1
call buildconf.bat 2>&1
if errorlevel 1 exit 2
call config.ts.bat 2>&1
if errorlevel 1 exit 3
nmake 2>&1
if errorlevel 1 exit 4
call phpsdk_pgo --init 2>&1
if errorlevel 1 exit 5
call phpsdk_pgo --train --scenario default 2>&1
if errorlevel 1 exit 6
call phpsdk_pgo --train --scenario cache 2>&1
if errorlevel 1 exit 7
nmake clean-pgo 2>&1
if errorlevel 1 exit 8
sed -i "s/enable-pgi/with-pgo/" config.ts.bat 2>&1
if errorlevel 1 exit 9
call config.ts.bat 2>&1
if errorlevel 1 exit 10
nmake && nmake snap 2>&1
if errorlevel 1 exit 11
