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
    extension-url: https://github.com/xdebug/xdebug
    extension-ref: '3.3.1'
    php-version: '8.3'
    ts: nts
    arch: x64
    args: --enable-xdebug
    libs: zlib
```

### Inputs

- `extension-url` (optional) - URL of the extension's git repository, defaults to the current repository.
- `extension-ref` (required) - The git reference to build the extension, defaults to the GitHub reference that triggered the workflow.
- `php-version` (required) - The PHP versions to build the extension for.
- `arch` (required) - The architecture to build the extension for.
- `ts` (required) - The thread safety to build the extension for.
- `args` (optional) - Additional arguments to pass to the `configure` script.
- `libs` (optional) - Libraries required for the extension.
- `run-tests` (optional) - Run the extension tests. Defaults to `true`.
- `test-runner` (optional) - The test runner to use. Defaults to `run-tests.php`.

Instead of having to configure all the inputs for the extension action, you can use the `extension-matrix` action to get the matrix of jobs with different input configurations.

## Get the job matrix to build a PHP extension

```yaml
jobs:
  get-extension-matrix:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Get the extension matrix
        id: extension-matrix
        uses: php/php-windows-builder/extension-matrix@v1
        with:
          extension-url: https://github.com/xdebug/xdebug
          extension-ref: '3.3.1'
          php-version-list: '8.3, 8.4'
          arch-list: 'x64, x86'
          ts-list: 'nts, ts'
```

### Inputs

- `extension-url` (optional) - URL of the extension's git repository, defaults to the current repository.
- `extension-ref` (optional) - The git reference to build the extension, defaults to the GitHub reference that triggered the workflow.
- `php-version-list` (optional) - The PHP versions to build the extension for. Defaults to the PHP versions required in the `composer.json` file.
- `arch-list` (optional) - The architectures to build the extension for. Defaults to `x64, x86`.
- `ts-list` (optional) - The thread safety to build the extension for. Defaults to `nts, ts`.
- `allow-old-php-versions` (optional) - Allow building the extension for older PHP versions. Defaults to `false`.

### Outputs

- `matrix` - The matrix of jobs with different input configurations.

### PHP Version Support

By default, the `extension-matrix` action will use the PHP versions defined in the `php-version-list` input.

If the `php-version-list` input is not provided, it will use the PHP versions required in the `composer.json` file.

It will also check if a GitHub hosted Windows runner is available with the required Visual Studio version to build the extension for the PHP version. To override this for building the extension for older PHP versions, you will have to set the input `allow_old_php_versions` to `true` and add self-hosted Windows runners as specified in the table below.

| PHP Version | Visual Studio Version | Windows Runner Labels       |
|-------------|-----------------------|-----------------------------|
| 7.0         | 2015 (vc14)           | windows-2012, self-hosted   |
| 7.1         | 2015 (vc14)           | windows-2012, self-hosted   |
| 7.2         | 2017 (vc15)           | windows-2016, self-hosted   |
| 7.3         | 2017 (vc15)           | windows-2016, self-hosted   |
| 7.4         | 2017 (vc15)           | windows-2016, self-hosted   |
| 8.0         | 2019 (vs16)           | windows-2019, github-hosted |
| 8.1         | 2019 (vs16)           | windows-2019, github-hosted |
| 8.2         | 2019 (vs16)           | windows-2019, github-hosted |
| 8.3         | 2019 (vs16)           | windows-2019, github-hosted |

## Release

Upload the artifacts to a release.

```yaml
- name: Upload artifact to the release
  uses: php/php-windows-builder/release@v1
  with:
    release: ${{ github.event.release.tag_name }}
    token: ${{ secrets.GITHUB_TOKEN }}
```

### Inputs

- `release` (required) - The release to upload the artifacts.
- `token` (required) - The GitHub token to authenticate with.

### Example workflow to build and release an extension

```yaml
name: Build extension
on:
  release:
    types: [published]
  # create: # Uncomment this to run on tag/branch creation
  # pull_request: # Uncomment this to run on pull requests  

# This may be needed to be able to upload the assets to the release
# See: https://docs.github.com/en/actions/security-guides/automatic-token-authentication#modifying-the-permissions-for-the-github_token
#permissions:
#  contents: write

jobs:
  get-extension-matrix:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.extension-matrix.outputs.matrix }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Get the extension matrix
        id: extension-matrix
        uses: php/php-windows-builder/extension-matrix@v1
  build:
    needs: get-extension-matrix
    runs-on: ${{ matrix.os }}
    strategy:
      matrix: ${{fromJson(needs.get-extension-matrix.outputs.matrix)}}
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Build the extension
        uses: php/php-windows-builder/extension@v1
        with:
          php-version: ${{ matrix.php-version }}
          arch: ${{ matrix.arch }}
          ts: ${{ matrix.ts }}
  release:
    runs-on: ubuntu-latest
    needs: build
    if: ${{ github.event_name == 'release' }}
    steps:
      - name: Upload artifact to the release
        uses: php/php-windows-builder/release@v1
        with:
          release: ${{ github.event.release.tag_name }}
          token: ${{ secrets.GITHUB_TOKEN }}
```

## License

The scripts and documentation in this project are released under the [MIT License](LICENSE)
