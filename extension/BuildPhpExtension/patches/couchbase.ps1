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
