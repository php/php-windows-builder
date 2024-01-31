# php-windows-builder

This project provides actions to build PHP and its extensions on Windows.

## Build PHP

Build PHP for a specific version, architecture and thread safety.

```yaml
- name: Build PHP
  uses: php/php-windows-builder/php@v1
  with:
    php-version: '8.3.2'
    arch: x64
    ts: nts
```

### Inputs

- `php-version` (required) - The PHP version to build. It supports values in major.minor.patch format, e.g. 7.4.25, 8.0.12, etc.
- `arch` (required) - The architecture to build. It supports values `x64` and `x86`.
- `ts` (required) - The thread safety to build. It supports values `ts` and `nts`.

### Outputs

- `artifact-path` - The path to the artifacts produced by the action.

### Example workflow to build PHP

```yaml
jobs:
  php:
    strategy:
      matrix:
        arch: [x64, x86]
        ts: [nts, ts]
    runs-on: windows-2019
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Build
        uses: php/php-windows-builder/php@v1
        with:
          php-version: '8.3.2'
          arch: ${{ matrix.arch }}
          ts: ${{ matrix.ts }}
```

The above workflow will produce the following the following builds for the PHP version `8.3.2` as artifacts.

- nts-x64, nts-x64-AVX, ts-x64, nts-x86, ts-x86.
- debug-pack and devel-pack for each the above configurations.
- test pack

## Build a PHP extension

Build a PHP extension for a specific version.

```yaml
- name: Build the extension
  uses: php/php-windows-builder/extension@v1
  with:
    extension-url: https://github.com/xdebug/xdebug # optional
    extension-version: '3.3.1'
    php-version: '8.3'
  env:
    CONFIGURE_ARGS: --enable-xdebug
```

### Inputs

- `extension-url` (optional) - URL of the extension repository, defaults to the current repository.
- `extension-version` (required) - The version of the extension to build.
- `php-versions` (optional) - The PHP versions to build the extension for. It supports a comma-separated list of values in major.minor format, e.g. 7.4, 8.0, etc. It defaults to the range defined in the `package.xml`.

### Outputs

- `artifact-path` - The path to the artifacts produced by the action.

The action will produce the following the following builds for the extension as artifacts.
- nts-x64, ts-x64, nts-x86, ts-x86.

## Release

Upload the artifacts to the release.

```yaml
- name: Upload artifact to the release
  uses: php/php-windows-builder/release@v1
  with:
    tag-name: ${{ github.event.release.tag_name }}
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Inputs

- `tag-name` (required) - The tag name of the release.

### Example workflow to build and release an extension

```yaml
name: Build extension
on:
  release:
    types: [published]
  # create: # Uncomment this to run on tag/branch creation
  # pull_request: # Uncomment this to run on pull requests  
jobs:
  build:
    runs-on: windows-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Build the extension
        uses: php/php-windows-builder/extension@v1
        with:
          extension-version: ${{ github.event.release.tag_name }}
  release:
    runs-on: ubuntu-latest
    needs: build
    if: ${{ github.event_name == 'release' }}
    steps:
      - name: Upload artifact to the release
        uses: php/php-windows-builder/release@v1
        with:
          tag-name: ${{ github.event.release.tag_name }}
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## License

The scripts and documentation in this project are released under the [MIT License](LICENSE)
