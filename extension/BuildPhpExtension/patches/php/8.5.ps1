$replacements = @{
  'ext/standard/php_smart_string.h'        = 'Zend/zend_smart_string.h'
  'ext/standard/php_smart_string_public.h' = 'Zend/zend_smart_string.h'
  'zend_exception_get_default()'           = 'zend_ce_exception'
  'zend_exception_get_default(TSRMLS_C)'   = 'zend_ce_exception'
}

$extensions = @('*.c', '*.h', '*.cpp', '*.hpp')

Get-ChildItem -Path . -Recurse -File -Include $extensions | ForEach-Object {
  $file = $_.FullName
  $content = Get-Content -Path $file -Raw
  $original = $content
  foreach ($old in $replacements.Keys) {
    $new = $replacements[$old]
    $content = $content.Replace($old, $new)
  }
  if ($content -ne $original) {
    Set-Content -Path $file -Value $content
  }
}
