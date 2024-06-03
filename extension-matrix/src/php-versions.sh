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
      if ! [ -e "$directory/$extension-$EXTENSION_REF.tgz" ] || file "$directory/$extension-$EXTENSION_REF.tgz" | grep -q HTML; then
        extension_upper="$(echo "$extension" | tr '[:lower:]' '[:upper:]')"
        curl -o "$directory/$extension-$EXTENSION_REF.tgz" -sL "https://pecl.php.net/get/$extension_upper-$EXTENSION_REF.tgz"
      fi
      if ! [ -e "$directory/$extension-$EXTENSION_REF.tgz" ] || file "$directory/$extension-$EXTENSION_REF.tgz" | grep -q HTML; then
        echo "Extension $extension not found on PECL"
        exit 1
      fi
      tar -xzf "$directory/$extension-$EXTENSION_REF.tgz" -C "$directory"
      cp -a "$directory/$extension-$EXTENSION_REF"/* "$directory"
    else
      [ -n "$AUTH_TOKEN" ] && EXTENSION_URL="https://${AUTH_TOKEN}@${EXTENSION_URL/https:\/\/}"
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
  vs_json="$SCRIPT_DIR"/../config/vs.json
  php_versions=$(jq -r 'keys | join(",")' "$vs_json")
  constraint=$(jq -r .require.php "$composer_json")
  php "$SCRIPT_DIR"/semver/semver.phar composer.json "$constraint" "$php_versions"
}

function compare_versions_using_package_xml() {
  local directory=$1
  local package_xml=$2
  SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
  vs_json="$SCRIPT_DIR"/../config/vs.json
  php_versions=$(jq -r 'keys | join(",")' "$vs_json")
  php "$SCRIPT_DIR"/semver/semver.phar package.xml "$package_xml" "$php_versions"
}

function get_package_json() {
  local directory=$1
  package_xmls=$(find "$directory" -name 'package*.xml')
  for file in $package_xmls; do
    grep -q '<php>' "$file" && echo "$file" && break
  done
}

function get_php_versions() {
  directory=$(mktemp -d)

  get_extension "$directory" > /dev/null 2>&1

  composer_json="$(find "$directory" -name composer.json -exec sh -c 'jq -e ".type == \"php-ext\"" "$1" >/dev/null && echo "$1"' sh {} \; | head -n 1)"
  package_xml=$(get_package_json "$directory")
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
