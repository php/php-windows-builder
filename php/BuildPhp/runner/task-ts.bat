set LDFLAGS="/d2:-AllowCompatibleILVersions" 2>&1
call buildconf.bat 2>&1
if errorlevel 1 exit 1
call config.ts.bat 2>&1
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
sed -i "s/enable-pgi/with-pgo/" config.ts.bat 2>&1
if errorlevel 1 exit 8
call config.ts.bat 2>&1
if errorlevel 1 exit 9
nmake && nmake snap 2>&1
if errorlevel 1 exit 10
