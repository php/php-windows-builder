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
    extension-url: https://github.com/xdebug/xdebug
    extension-ref: '3.3.1'
    php-version: '8.3'
    ts: nts
    arch: x64
  env:
    CONFIGURE_ARGS: --enable-xdebug
```

### Inputs

- `extension-url` (optional) - URL of the extension's git repository, defaults to the current repository.
- `extension-ref` (required) - The git reference to build the extension, defaults to the GitHub reference that triggered the workflow.
- `php-version` (required) - The PHP versions to build the extension for.
- `arch` (required) - The architecture to build the extension for.
- `ts` (required) - The thread safety to build the extension for.

### Outputs

- `artifact-path` - The path to the artifacts produced by the action.

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
- `php-version-list` (optional) - The PHP versions to build the extension for. Defaults to the PHP versions defined in the `package.xml` file.
- `arch-list` (optional) - The architectures to build the extension for. Defaults to `x64, x86`.
- `ts-list` (optional) - The thread safety to build the extension for. Defaults to `nts, ts`.

### Outputs

- `matrix` - The matrix of jobs with different input configurations.

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
    runs-on: windows-latest
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
          tag-name: ${{ github.event.release.tag_name }}
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## License

The scripts and documentation in this project are released under the [MIT License](LICENSE)
