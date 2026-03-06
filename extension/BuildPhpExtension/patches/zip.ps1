$fn = @"
ADD_FLAG("LDFLAGS_ZIP", "/FORCE:MULTIPLE");
AC_DEFINE('HAVE_LIBZIP', 1);
"@
(Get-Content config.w32) | ForEach-Object { $_.Replace("AC_DEFINE('HAVE_LIBZIP', 1);", $fn) } | Set-Content config.w32
