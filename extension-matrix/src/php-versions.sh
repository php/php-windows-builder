#!/usr/bin/env bash

compare_versions() {
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

filter_versions() {
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
    git -C "$directory" init
    git -C "$directory" remote add origin "$EXTENSION_URL"
    git -C "$directory" fetch --depth=1 origin "$EXTENSION_REF"
    git -C "$directory" checkout FETCH_HEAD
  fi
}

get_php_versions() {
  directory=$(mktemp -d)

  get_extension "$directory" > /dev/null 2>&1

  package_xml=$(find "$directory" -name package.xml)
  if [ -z "${package_xml}" ]; then
      echo "package.xml not found"
      exit 1
  fi

  min_version=$(grep '<min>' "$package_xml" | head -1 | sed -e 's/<[^>]*>//g' | cut -d'.' -f1,2 | xargs)
  max_version=$(grep '<max>' "$package_xml" | head -1 | sed -e 's/<[^>]*>//g' | cut -d'.' -f1,2 | xargs)

  states="$(curl -sL https://www.php.net/releases/states.php)"
  IFS=' ' read -r -a php_versions <<< "$(echo "$states" | jq -r 'to_entries[] | .key as $major | .value | to_entries[] | .key' | sort -Vu | tr '\n' ' ')"

  [[ -z "$max_version" ]] && max_version="${php_versions[-1]}"

  rm -rf "$directory"

  filter_versions "$min_version" "$max_version" "${php_versions[@]}"
}
