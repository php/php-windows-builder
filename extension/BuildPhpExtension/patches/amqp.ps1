$file = "amqp_type.c"
$content = Get-Content -LiteralPath $file -Raw -Encoding utf8
$include = '#include <inttypes.h>'
$anchor = '#include "Zend/zend_interfaces.h"'

if (-not $content.Contains($include)) {
    if (-not $content.Contains($anchor)) {
        throw "Unable to add inttypes.h include to $file"
    }
    $content = $content.Replace($anchor, "$include`r`n$anchor")
    Set-Content -LiteralPath $file -Value $content -Encoding utf8
}
