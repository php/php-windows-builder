$fn = @"
ARG_ENABLE("http", "whether to enable extended HTTP support", "no");

base_dir = get_define('BUILD_DIR');
if (!FSO.FolderExists(base_dir+"\\src")) {
	WScript.Echo("Creating " + base_dir + "\\src" + "...");
	FSO.CreateFolder(base_dir+"\\src");
}
"@

(Get-Content config.w32) | ForEach-Object { $_.Replace('ARG_ENABLE("http", "whether to enable extended HTTP support", "no");', $fn) } | Set-Content config.w32
