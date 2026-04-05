$path = "config.w32"
$content = Get-Content $path -Raw
$old = "        AC_DEFINE('PHP_SSH2_CHANNEL_SIGNAL', 1);"
$new = @"
        if (CHECK_FUNC_IN_HEADER("libssh2.h", "libssh2_channel_signal_ex", PHP_PHP_BUILD + "\\include\\libssh2")) {
            AC_DEFINE('PHP_SSH2_CHANNEL_SIGNAL', 1);
        }
"@

if ($content.Contains($old)) {
    Set-Content $path -Value ($content.Replace($old, $new))
}
