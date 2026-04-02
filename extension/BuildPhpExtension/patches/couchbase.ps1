$path = 'src/deps/couchbase-cxx-client/core/websocket_codec.cxx'
(Get-Content $path) `
  -replace 'static_cast<std::byte>\(\(length >> 56\) & 0xff\)', 'static_cast<std::byte>((static_cast<std::uint64_t>(length) >> 56) & 0xff)' `
  -replace 'static_cast<std::byte>\(\(length >> 48\) & 0xff\)', 'static_cast<std::byte>((static_cast<std::uint64_t>(length) >> 48) & 0xff)' `
  -replace 'static_cast<std::byte>\(\(length >> 40\) & 0xff\)', 'static_cast<std::byte>((static_cast<std::uint64_t>(length) >> 40) & 0xff)' `
  -replace 'static_cast<std::byte>\(\(length >> 32\) & 0xff\)', 'static_cast<std::byte>((static_cast<std::uint64_t>(length) >> 32) & 0xff)' `
  -replace 'static_cast<std::byte>\(\(length >> 24\) & 0xff\)', 'static_cast<std::byte>((static_cast<std::uint64_t>(length) >> 24) & 0xff)' `
  -replace 'static_cast<std::byte>\(\(length >> 16\) & 0xff\)', 'static_cast<std::byte>((static_cast<std::uint64_t>(length) >> 16) & 0xff)' `
  -replace 'static_cast<std::byte>\(\(length >> 8\) & 0xff\)',  'static_cast<std::byte>((static_cast<std::uint64_t>(length) >> 8) & 0xff)' `
  -replace 'static_cast<std::byte>\(length & 0xff\)',           'static_cast<std::byte>(static_cast<std::uint64_t>(length) & 0xff)' |
        Set-Content $path

$path = 'src/php_couchbase.cxx'
(Get-Content $path) `
  -replace 'std::int64_t value = 0;', 'zend_long value = 0;' `
  -replace 'handle->record_core_meter_operation_duration\(value, tags\);', 'handle->record_core_meter_operation_duration(static_cast<std::int64_t>(value), tags);' |
        Set-Content $path
