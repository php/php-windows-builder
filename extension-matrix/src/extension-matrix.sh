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

vs_json=extension-matrix/config/vs.json
filtered_versions=$(jq -r 'keys | join(" ")' "$vs_json")
if [[ -z "$ALLOW_OLD_PHP_VERSIONS" || "$ALLOW_OLD_PHP_VERSIONS" == "false" ]]; then
  filtered_versions=$(jq -r 'to_entries | map(select(.value.type == "github-hosted") | .key) | join(" ")' "$vs_json")
fi

found='false'
for php_version in "${php_version_array[@]}"; do
  if [[ " $filtered_versions " =~ $php_version ]]; then
    found='true'
  else
    continue
  fi
  os=$(jq -r --arg php_version "$php_version" '.[$php_version].os' "$vs_json")
  for arch in "${arch_array[@]}"; do
    for ts in "${ts_array[@]}"; do
      matrix+=("{\"os\": \"$os\", \"php-version\": \"$php_version\", \"arch\": \"$arch\", \"ts\": \"$ts\"}")
    done
  done
done

if [[ "$found" == 'false' ]]; then
  echo "No PHP versions found for the specified inputs"
  echo "Please refer to the PHP version support in the README"
  echo "https://github.com/php/php-windows-builder#php-version-support"
  exit 1
fi

# shellcheck disable=SC2001
echo "matrix={\"include\":[$(echo "${matrix[@]}" | sed -e 's|} {|}, {|g')]}" >> "$GITHUB_OUTPUT"
