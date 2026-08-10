$compatHeader = @"
#ifndef MYSQL_XDEVAPI_PROTOBUF_MSVC_COMPAT_H
#define MYSQL_XDEVAPI_PROTOBUF_MSVC_COMPAT_H

/* protobuf 3.5 uses std::hash_compare, which was removed in MSVC 14.44. */
#if defined(_MSC_VER) && _MSC_VER >= 1944
#define _STLPORT_VERSION 1
#include <google/protobuf/stubs/hash.h>
#undef _STLPORT_VERSION
#endif

#endif
"@
Set-Content -LiteralPath "protobuf_msvc_compat.h" -Value $compatHeader -Encoding utf8

$file = "php_api.h"
$content = Get-Content -LiteralPath $file -Raw -Encoding utf8
$iteratorResult = @"
#if PHP_VERSION_ID >= 80400
using iterator_result = zend_result;
#else
using iterator_result = int;
#endif
"@
$anchor = "using raw_zval = zval;"

if (-not $content.Contains("using iterator_result")) {
    if (-not $content.Contains($anchor)) {
        throw "Unable to add the iterator result compatibility type to $file"
    }
    $content = $content.Replace($anchor, "$anchor`r`n`r`n$iteratorResult")
    Set-Content -LiteralPath $file -Value $content -Encoding utf8
}

$fieldTypeCompat = @"
#if PHP_VERSION_ID >= 80400
#define FIELD_TYPE_INTERVAL FIELD_TYPE_ENUM
#endif
"@
$anchor = '#define MYSQLX_LLU_SPEC "%" PRIu64'

if (-not $content.Contains("#define FIELD_TYPE_INTERVAL")) {
    if (-not $content.Contains($anchor)) {
        throw "Unable to add the interval field type compatibility definition to $file"
    }
    $content = $content.Replace($anchor, "$anchor`r`n`r`n$fieldTypeCompat")
    Set-Content -LiteralPath $file -Value $content -Encoding utf8
}

$iteratorFiles = @(
    "mysqlx_doc_result_iterator.cc",
    "mysqlx_result_iterator.cc",
    "mysqlx_row_result_iterator.cc",
    "mysqlx_sql_statement_result_iterator.cc"
)
$validMethodPattern = '(?m)^static int\r?\n(?=XMYSQLND_METHOD\([^,\r\n]+, valid\)\(zend_object_iterator \* iter\))'

foreach ($iteratorFile in $iteratorFiles) {
    $content = Get-Content -LiteralPath $iteratorFile -Raw -Encoding utf8
    if (-not $content.Contains("static util::iterator_result")) {
        if (-not [regex]::IsMatch($content, $validMethodPattern)) {
            throw "Unable to update the iterator result type in $iteratorFile"
        }
        $content = [regex]::Replace($content, $validMethodPattern, "static util::iterator_result`r`n", 1)
        Set-Content -LiteralPath $iteratorFile -Value $content -Encoding utf8
    }
}

$file = "xmysqlnd\xmysqlnd_session.cc"
$content = Get-Content -LiteralPath $file -Raw -Encoding utf8
$anchor = '#include <ext/hash/php_hash.h>'
$hashHeaderCompat = @"
#if PHP_VERSION_ID >= 80400
#pragma push_macro("ecalloc")
#undef ecalloc
#define ecalloc(nmemb, size) ((char *) _ecalloc((nmemb), (size) ZEND_FILE_LINE_CC ZEND_FILE_LINE_EMPTY_CC))
#endif
#include <ext/hash/php_hash.h>
#if PHP_VERSION_ID >= 80400
#pragma pop_macro("ecalloc")
#endif
"@

if (-not $content.Contains('#pragma push_macro("ecalloc")')) {
    if (-not $content.Contains($anchor)) {
        throw "Unable to add the PHP hash header compatibility fix to $file"
    }
    $content = $content.Replace($anchor, $hashHeaderCompat)
    Set-Content -LiteralPath $file -Value $content -Encoding utf8
}

$file = "config.w32"
$content = Get-Content -LiteralPath $file -Raw -Encoding utf8
$option = '"/FI" + get_src_path("protobuf_msvc_compat.h", true),'
$anchor = '"/EHsc", // enable exceptions'

if (-not $content.Contains($option)) {
    if (-not $content.Contains($anchor)) {
        throw "Unable to add the protobuf compatibility header to $file"
    }
    $content = $content.Replace($anchor, "$anchor`r`n`t`t$option")
    Set-Content -LiteralPath $file -Value $content -Encoding utf8
}
