$fn = @"
ARG_WITH("grpc", "grpc support", "no");
function CreateFolderIfMissing(path) {
    if (!path) return;
    if (!FSO.FolderExists(path)) {
        WScript.Echo("Creating " + path + "...");
        FSO.CreateFolder(path);
    }
}
"@
(Get-Content config.w32) | ForEach-Object { $_.Replace('base_dir+"\\ext\\grpc', 'base_dir+"') } | Set-Content config.w32
(Get-Content config.w32) | ForEach-Object { $_.Replace('FSO.CreateFolder', 'CreateFolderIfMissing') } | Set-Content config.w32
(Get-Content config.w32) | ForEach-Object { $_ -replace '/D_WIN32_WINNT=0x600', '/D_WIN32_WINNT=0x600 /FS /std:c++17' } | Set-Content config.w32
(Get-Content config.w32) | ForEach-Object { $_.Replace('ARG_WITH("grpc", "grpc support", "no");', $fn) } | Set-Content config.w32

$wrapperPath = "src\php\ext\grpc\php7_wrapper.h"
if (Test-Path $wrapperPath) {
    $wrapperContent = (Get-Content $wrapperPath -Raw) -replace "`r`n", "`n"
    $wrapperContent = $wrapperContent.Replace('#define PHP_GRPC_CALL_FUNCTION(fci, fci_cache) ({ \', '#define PHP_GRPC_CALL_FUNCTION(fci, fci_cache) do { \')
    $wrapperContent = $wrapperContent.Replace('  int _res = zend_call_function(fci, fci_cache TSRMLS_CC); \', '  zend_call_function(fci, fci_cache TSRMLS_CC); \')
    $wrapperContent = $wrapperContent.Replace("  _res; \`n})", "  } while (0)")
    Set-Content $wrapperPath $wrapperContent
}
