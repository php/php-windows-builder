function Get-ExtensionName {
  <#
    .SYNOPSIS
        Get the PHP extension name.
    #>
  [OutputType()]
  param (
  )
  begin {
  }
  process {
    $configW32Content = Get-Content -Path "config.w32"
    $extMatch = [regex]::Matches(
        $configW32Content,
        '(?is)\b(?:ZEND_)?EXTENSION\s*\(\s*(?<arg>.*?)\s*,'
    ) | Select-Object -Last 1

    if (-not $extMatch) {
      throw "No extension found in config.w32 ($Path)"
    }

    $token = $extMatch.Groups['arg'].Value.Trim()

    if ($token.Length -ge 2 -and (
    ($token[0] -eq "'" -and $token[-1] -eq "'") -or
        ($token[0] -eq '"' -and $token[-1] -eq '"')
    )) {
      $name = $token.Trim('"', "'").Trim()
    }
    else {
      $varNameEsc = [regex]::Escape($token)

      $assignPattern =
      '(?is)(?:^|[;{\s])' +
          '(?:(?:var|let|const)\s+)?' +
          $varNameEsc +
          '\s*=\s*(?<q>["\x27])(?<val>[^"\x27]+)\k<q>'

      $m = [regex]::Match($configW32Content, $assignPattern)
      if ($m.Success) {
        $val = $m.Groups['val'].Value
        if ($val -and $val -ne 'no') {
          $name = $val
        } else {
          $name = $token
        }
      } else {
        $name = $token
      }
    }
    if ($name -like '*oci8*') {
      $name = 'oci8_19'
    }
    return $name.Trim()
  }
  end {
  }
}