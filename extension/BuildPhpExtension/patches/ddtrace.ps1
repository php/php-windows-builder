Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DataDog/dd-trace-php/master/datadog-windows.sym" -OutFile "datadog-windows.sym"
Remove-Item -Path "libdatadog/Cargo.toml" -Force
