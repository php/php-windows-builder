$file = "xmysqlnd\xmysqlnd_session.cc"
$content = Get-Content -LiteralPath $file -Raw -Encoding utf8
$content = $content -replace '(?ms)^([ \t]*)if\s*\(\s*FAIL\s*==\s*mysqlnd_error_info_init\(&error_info_impl,\s*persistent\)\s*\)\s*\{\s*\r?\n[ \t]*throw\s+std::runtime_error\("mysqlnd_error_info_init failed"\);\s*\r?\n\1\}', '$1mysqlnd_error_info_init(&error_info_impl, persistent);'
Set-Content -LiteralPath $file -Value $content -Encoding utf8

$file = "xmysqlnd\xmysqlnd_protocol_frame_codec.cc"
$content = Get-Content -LiteralPath $file -Raw -Encoding utf8
$content = $content -replace 'DBG_INF_FMT\(\s*"count="\s*MYSQLND_SZ_T_SPEC\s*,\s*count\s*\)\s*;', 'DBG_INF_FMT("count=%zu", count);'
Set-Content -LiteralPath $file -Value $content -Encoding utf8
