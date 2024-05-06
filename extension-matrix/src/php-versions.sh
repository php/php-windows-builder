#!/usr/bin/env bash

function compare_versions() {
    local version1="$1"
    local version2="$2"

    first_sorted=$(printf "%s\n%s\n" "$version1" "$version2" | sort -V | head -n 1)

    if [ "$first_sorted" == "$version1" ]; then
        if [ "$version1" == "$version2" ]; then
            echo 0
        else
            echo -1
        fi
    else
        echo 1
    fi
}

function filter_versions() {
    local min_version=$1
    local max_version=$2
    local versions=("${@:3}")
    local filtered=()

    for version in "${versions[@]}"; do
        low=$(compare_versions "$version" "$min_version")
        high=$(compare_versions "$version" "$max_version")
        if [ "$low" -ge 0 ] && [ "$high" -le 0 ]; then
            filtered+=("$version")
        fi
    done

    echo "${filtered[@]}" | tr ' ' ','
}

function get_extension() {
  local directory=$1
  if [ -n "$EXTENSION_URL" ]; then
    # TODO: Remove this after PECL is deprecated
    if [[ "$EXTENSION_URL" = *"pecl.php.net"* ]] && [ -n "$EXTENSION_REF" ]; then
      extension="$(basename "$EXTENSION_URL")"
      curl -o "$directory/$extension-$EXTENSION_REF.tgz" -sL "https://pecl.php.net/get/$extension-$EXTENSION_REF.tgz"
      tar -xzf "$directory/$extension-$EXTENSION_REF.tgz" -C "$directory"
      cp -a "$directory/$extension-$EXTENSION_REF"/* "$directory"
    else
      git -C "$directory" init
      git -C "$directory" remote add origin "$EXTENSION_URL"
      git -C "$directory" fetch --depth=1 origin "$EXTENSION_REF"
      git -C "$directory" checkout FETCH_HEAD
    fi
  fi
}

function compare_versions_using_composer() {
  local directory=$1
  local composer_json=$2
  SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
  states="$(curl -sL https://www.php.net/releases/states.php)"
  php_versions="$(echo "$states" | jq -r 'to_entries[] | .key as $major | .value | to_entries[] | .key' | sort -Vu | tr '\n' ',')"
  constraint=$(jq -r .require.php "$composer_json")
  php "$SCRIPT_DIR"/semver/semver.phar composer.json "$constraint" "$php_versions"
}

function compare_versions_using_package_xml() {
  local directory=$1
  local package_xml=$2
  SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
  states="$(curl -sL https://www.php.net/releases/states.php)"
  php_versions="$(echo "$states" | jq -r 'to_entries[] | .key as $major | .value | to_entries[] | .key' | sort -Vu | tr '\n' ',')"
  php "$SCRIPT_DIR"/semver/semver.phar package.xml "$package_xml" "$php_versions"
}

function get_php_versions() {
  directory=$(mktemp -d)

  get_extension "$directory" > /dev/null 2>&1

  composer_json="$(find "$directory" -name composer.json -exec sh -c 'jq -e ".type == \"php-ext\"" "$1" >/dev/null && echo "$1"' sh {} \; | head -n 1)"
  package_xml=$(find "$directory" -name package.xml)
  if [ -n "$composer_json" ]; then
    compare_versions_using_composer "$directory" "$composer_json"
    rm -rf "$directory"
  elif [ -n "$package_xml" ]; then
    compare_versions_using_package_xml "$directory" "$package_xml"
    rm -rf "$directory"
  else
    echo "No composer.json with type php-ext or package.xml found"
    exit 1
  fi
}
