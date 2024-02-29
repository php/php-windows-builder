#!/usr/bin/env bash

. extension-matrix/src/php-versions.sh

matrix=();

[ -n "$EXTENSION_URL" ] && [ -z "$EXTENSION_REF" ] && EXTENSION_REF="${GITHUB_SHA:?}"

[ -z "$PHP_VERSION_LIST" ] && \
  PHP_VERSION_LIST="$(get_php_versions "$EXTENSION_URL" "$EXTENSION_REF")"
[ -z "$ARCH_LIST" ] && ARCH_LIST="x64,x86"
[ -z "$TS_LIST" ] && TS_LIST="nts,ts"

IFS=',' read -r -a php_version_array <<<"${PHP_VERSION_LIST// /}"
IFS=',' read -r -a arch_array <<<"${ARCH_LIST// /}"
IFS=',' read -r -a ts_array <<<"${TS_LIST// /}"

for php_version in "${php_version_array[@]}"; do
  for arch in "${arch_array[@]}"; do
    for ts in "${ts_array[@]}"; do
      matrix+=("{\"php-version\": \"$php_version\", \"arch\": \"$arch\", \"ts\": \"$ts\"}")
    done
  done
done

# shellcheck disable=SC2001
echo "matrix={\"include\":[$(echo "${matrix[@]}" | sed -e 's|} {|}, {|g')]}" >> "$GITHUB_OUTPUT"
