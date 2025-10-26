# php-windows-builder

This project provides PowerShell packages and GitHub Actions to build PHP and its extensions on Windows.

## Index

- [GitHub Actions](#github-actions)
    - [Build PHP](#build-php)
        - [Inputs](#inputs)
        - [Example workflow to build PHP](#example-workflow-to-build-php)
    - [Build a PHP extension](#build-a-php-extension)
        - [Inputs](#inputs-1)
    - [Get the job matrix to build a PHP extension](#get-the-job-matrix-to-build-a-php-extension)
        - [Inputs](#inputs-2)
        - [Outputs](#outputs)
        - [PHP Version Support](#php-version-support)
    - [Release](#release)
        - [Inputs](#inputs-3)
        - [Example workflow for non-immutable releases](#example-workflow-for-non-immutable-releases)
        - [Example workflow for immutable releases](#example-workflow-for-immutable-releases)

- [Local Setup](#local-setup)
    - [PHP](#php)
    - [PHP Extensions](#php-extensions)

- [License](#license)

## GitHub Actions

### Build PHP

Build a specific version of PHP, with the required architecture and thread safety.

```yaml
- name: Build PHP
  uses: php/php-windows-builder/php@v1
  with:
    php-version: '8.4.11'
    arch: x64
    ts: nts
```

#### Inputs

- `php-version` (required) - The PHP version to build. It supports values in major.minor.patch format, e.g. 7.4.25, 8.0.12, etc., or `master` for the master branch of `php-src`.
- `arch` (required) - The architecture to build. It supports values `x64` and `x86`.
- `ts` (required) - The thread safety to build. It supports values `ts` and `nts`.

#### Example workflow to build PHP

```yaml
jobs:
  php:
    strategy:
      matrix:
        arch: [x64, x86]
        ts: [nts, ts]
    runs-on: windows-2022
    steps:
      - name: Checkout
        uses: actions/checkout@v5

      - name: Build
        uses: php/php-windows-builder/php@v1
        with:
          php-version: '8.4.11'
          arch: ${{ matrix.arch }}
          ts: ${{ matrix.ts }}
```

The above workflow will produce the following builds for the PHP version `8.4.1` as artifacts.

- nts-x64, nts-x64-AVX, ts-x64, nts-x86, ts-x86.
- debug-pack and devel-pack for each the above configurations.
- test pack

### Build a PHP extension

Build a specific version of a PHP extension.

```yaml
- name: Build the extension
  uses: php/php-windows-builder/extension@v1
  with:
    extension-url: https://github.com/xdebug/xdebug
    extension-ref: '3.4.5'
    php-version: '8.3'
    ts: nts
    arch: x64
    args: --with-xdebug
    libs: zlib
```

#### Inputs

- `extension-url` (optional) - URL of the extension's git repository, defaults to the current repository.
- `extension-ref` (optional) - The git reference to build the extension, defaults to the GitHub reference that triggered the workflow.
- `php-version` (required) - The PHP versions to build the extension for.
- `arch` (required) - The architecture to build the extension for.
- `ts` (required) - The thread safety to build the extension for.
- `args` (optional) - Additional arguments to pass to the `configure` script.
- `libs` (optional) - Libraries required for the extension.
- `build-directory` (optional) - The directory to build the extension in, defaults to the user's temporary directory.
- `run-tests` (optional) - Run the extension tests. Defaults to `true`.
- `test-runner` (optional) - The test runner to use. Defaults to `run-tests.php`.
- `test-runner-args` (optional) - Arguments to pass to the test runner.
- `test-opcache-mode` (optional) - Run tests with opcache `on`, `off` or `both`. Defaults to `off`.
- `test-workers` (optional) - The number of workers to use when running tests. Defaults to `8`.
- `auth-token` (optional) - Authentication token to use in case the extension is hosted on a private repository.

Instead of having to configure all the inputs for the extension action, you can use the `extension-matrix` action to get the matrix of jobs with different input configurations.

### Get the job matrix to build a PHP extension

```yaml
jobs:
  get-extension-matrix:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v5
      - name: Get the extension matrix
        id: extension-matrix
        uses: php/php-windows-builder/extension-matrix@v1
        with:
          extension-url: https://github.com/xdebug/xdebug
          extension-ref: '3.4.5'
          php-version-list: '8.2, 8.3'
          arch-list: 'x64, x86'
          ts-list: 'nts, ts'
```

#### Inputs

- `extension-url` (optional) - URL of the extension's git repository, defaults to the current repository.
- `extension-ref` (optional) - The git reference to build the extension, defaults to the GitHub reference that triggered the workflow.
- `php-version-list` (optional) - The PHP versions to build the extension for. Defaults to the PHP versions required in the `composer.json` file.
- `arch-list` (optional) - The architectures to build the extension for. Defaults to `x64, x86`.
- `ts-list` (optional) - The thread safety to build the extension for. Defaults to `nts, ts`.
- `allow-old-php-versions` (optional) - Allow building the extension for older PHP versions. Defaults to `false`.
- `auth-token` (optional) - Authentication token to use in case the extension is hosted on a private repository.

#### Outputs

- `matrix` - The matrix of jobs with different input configurations.

#### PHP Version Support

By default, the `extension-matrix` action will use the PHP versions defined in the `php-version-list` input.

If the `php-version-list` input is not provided, it will use the PHP versions required in the `composer.json` file.

It will also check if a GitHub hosted Windows runner is available with the required Visual Studio version to build the extension for the PHP version or try to install it. To override this for building the extension for older PHP versions, you will have to set the input `allow_old_php_versions` to `true` and add self-hosted Windows runners as specified in the table below.

| PHP Version | Visual Studio Version | Windows Runner Labels       |
|-------------|-----------------------|-----------------------------|
| 7.0         | 2015 (vc14)           | windows-2012, self-hosted   |
| 7.1         | 2015 (vc14)           | windows-2012, self-hosted   |
| 7.2         | 2017 (vc15)           | windows-2022, github-hosted |
| 7.3         | 2017 (vc15)           | windows-2022, github-hosted |
| 7.4         | 2017 (vc15)           | windows-2022, github-hosted |
| 8.0         | 2019 (vs16)           | windows-2022, github-hosted |
| 8.1         | 2019 (vs16)           | windows-2022, github-hosted |
| 8.2         | 2019 (vs16)           | windows-2022, github-hosted |
| 8.3         | 2019 (vs16)           | windows-2022, github-hosted |
| 8.4         | 2022 (vs17)           | windows-2022, github-hosted |
| 8.5         | 2022 (vs17)           | windows-2022, github-hosted |
| master      | 2022 (vs17)           | windows-2022, github-hosted |

### Release

Upload the artifacts to a release.

```yaml
- name: Upload artifact to the release
  uses: php/php-windows-builder/release@v1
  with:
    release: ${{ github.event.release.tag_name }}
    token: ${{ secrets.GITHUB_TOKEN }}
```

#### Inputs

- `release` (required) - The release/tag to upload the artifacts.
- `token` (optional) - The GitHub token to authenticate with. Defaults to `GITHUB_TOKEN` secret.
- `draft` (optional) - Whether to create a draft release if the release does not exist. Defaults to `false`.

#### Example workflow for non-immutable releases

Follow this if you are creating the release and they are not immutable (This is the default).

For non-immutable releases, you can publish them, and the workflow will upload the extension builds to the release.

```yaml
name: Build extension
on:
  # When a new release is created, we can build, and upload the DLLs to it.
  release:
    types: [created]
  # push: # Uncomment this to run on push to a branch
  # create: # Uncomment this to run on tag/branch creation
  # pull_request: # Uncomment this to run on pull requests  

permissions:
  contents: write

jobs:
  # This job generates a matrix of PHP versions, architectures, and thread safety options
  # This is done by reading the constraints from composer.json or the package.xml file.
  # Please refer to https://github.com/php/php-windows-builder#get-the-job-matrix-to-build-a-php-extension
  get-extension-matrix:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.extension-matrix.outputs.matrix }}
    steps:
      - name: Checkout
        uses: actions/checkout@v5

      - name: Get the extension matrix
        id: extension-matrix
        uses: php/php-windows-builder/extension-matrix@v1

  # This job builds the extension on Windows using the matrix generated from the previous job.      
  build:
    needs: get-extension-matrix
    runs-on: ${{ matrix.os }}
    strategy:
      matrix: ${{fromJson(needs.get-extension-matrix.outputs.matrix)}}
    steps:
      - name: Checkout
        uses: actions/checkout@v5

      - name: Build the extension
        uses: php/php-windows-builder/extension@v1
        with:
          # Always specify the php-version, arch, and ts as they are required inputs.
          # Please refer to https://github.com/php/php-windows-builder#build-a-php-extension
          php-version: ${{ matrix.php-version }}
          arch: ${{ matrix.arch }}
          ts: ${{ matrix.ts }}
          
  # This job uploads the built artifacts to the GitHub release.
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

#### Example workflow for immutable releases

Follow this if you are using immutable releases.

For immutable releases, please do not create a new release using the GitHub UI, you can push a new tag, and the workflow will create a new release, build the extension, and upload the builds to the release.

It publishes the release by default, and then you can edit the release notes as needed, If you want to create a draft release, set the `draft` input to `true` in the `release` job.

```yaml
name: Build extension
on:
  # When a new tag is pushed, we can build, and upload the DLLs to it.
  push:
    # branches: ['**'] # Uncomment this to run on push to a branch
    tags: ['*']
  # create: # Uncomment this to run on tag/branch creation
  # pull_request: # Uncomment this to run on pull requests  

permissions:
  contents: write

jobs:
  # This job generates a matrix of PHP versions, architectures, and thread safety options
  # This is done by reading the constraints from composer.json or the package.xml file.
  # Please refer to https://github.com/php/php-windows-builder#get-the-job-matrix-to-build-a-php-extension
  get-extension-matrix:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.extension-matrix.outputs.matrix }}
    steps:
      - name: Checkout
        uses: actions/checkout@v5

      - name: Get the extension matrix
        id: extension-matrix
        uses: php/php-windows-builder/extension-matrix@v1

  # This job builds the extension on Windows using the matrix generated from the previous job.      
  build:
    needs: get-extension-matrix
    runs-on: ${{ matrix.os }}
    strategy:
      matrix: ${{fromJson(needs.get-extension-matrix.outputs.matrix)}}
    steps:
      - name: Checkout
        uses: actions/checkout@v5

      - name: Build the extension
        uses: php/php-windows-builder/extension@v1
        with:
          # Always specify the php-version, arch, and ts as they are required inputs.
          # Please refer to https://github.com/php/php-windows-builder#build-a-php-extension
          php-version: ${{ matrix.php-version }}
          arch: ${{ matrix.arch }}
          ts: ${{ matrix.ts }}
          
  # This job uploads the build artifacts to the immutable GitHub release it creates.
  release:
    runs-on: ubuntu-latest
    needs: build
    if: ${{ github.event_name == 'push' && startsWith(github.ref, 'refs/tags/') }}
    steps:
      - name: Upload artifact to the release
        uses: php/php-windows-builder/release@v1
        with:
          release: ${{ github.ref }}
          token: ${{ secrets.GITHUB_TOKEN }}
          # Uncomment the line below to create a draft release
          # draft: 'true' 
```

For more example workflows, please refer to the [examples](./examples) directory.

## Local Setup

### PHP

To build PHP locally, you can install the `BuildPhp` powershell module from the PowerShell Gallery:

You'll need at least PowerShell version 5, which is available by default on Windows 10 and later. It is recommended to use PowerShell 7 or later.
If you have an older version, you can install the latest version [following these instructions](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows).

Open an elevated PowerShell session (Run as Administrator) and run the following command to install the module:

```powershell
Install-Module -Name BuildPhp -Repository PSGallery -Force
```

To install this module for the current user only:

```powershell
Install-Module -Name BuildPhp -Repository PSGallery -Force -Scope CurrentUser
```

Next, make sure you have the required Visual Studio version installed to build the PHP version you want. You can find the required Visual Studio version in the [PHP Version Support table](#php-version-support) above.
If the required Visual Studio version is not installed, for the first time you try to build PHP, the module will try to install the required Visual Studio components automatically.

Then, you can build PHP by using the `Invoke-PhpBuild` command.
- To build a specific PHP version, you can use the `PhpVersion` input. It supports values in major.minor.patch format, e.g., 7.4.25, 8.0.12, etc., or `master` for the master branch of `php-src`.
- To build a 32-bit or a 64-bit version, you can use the `Arch` input. It supports values `x64` and `x86`.
- To build a thread-safe or non-thread-safe version, you can use the `Ts` input. It supports values `ts` and `nts`.

```powershell
Invoke-PhpBuild -PhpVersion '8.4.11' -Arch x64 -Ts nts
```

To build PHP from a local source, run `Invoke-PhpBuild` from the source directory and omit the `PhpVersion` input.

```powershell
Invoke-PhpBuild -Arch x64 -Ts nts
```

It should produce the PGO optimized builds for the input PHP version and configuration in a directory named `artifacts` in the current directory.

### PHP Extensions

To build a PHP extension locally, you can install the `BuildPhpExtension` powershell module from the PowerShell Gallery:
Again, You'll need at least PowerShell version 5, which is available by default on Windows 10 and later. It is recommended to use PowerShell 7 or later.
If you have an older version, you can install the latest version [following these instructions](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows).

Open an elevated PowerShell session (Run as Administrator) and run the following command to install the module:

```powershell
Install-Module -Name BuildPhpExtension -Repository PSGallery -Force
```

To install this module for the current user only:

```powershell
Install-Module -Name BuildPhpExtension -Repository PSGallery -Force -Scope CurrentUser
```

Next, make sure you have the required Visual Studio version installed to build the PHP extension you want. You can find the required Visual Studio version in the [PHP Version Support table](#php-version-support) above based on the PHP version you are building the PHP extension for.
If the required Visual Studio version is not installed, for the first time you try to build the PHP extension, the module will try to install the required Visual Studio components automatically.

Then, you can build the PHP extension by using the `Invoke-PhpBuildExtension` command.
- To build a php extension from a git repository, you can use the `ExtensionUrl` input. It supports a git repository URL as value.
- To build a specific version of the extension, you can use the `ExtensionRef` input. It supports a git reference, e.g., a tag or a branch as value.
- To build the extension for a specific PHP version, you can use the `PhpVersion` input. It supports values in major.minor format, e.g., 7.4, 8.0, etc.
- To build the extension for a 32-bit or a 64-bit PHP version, you can use the `Arch` input. It supports values `x64` and `x86`.
- To build the extension for a thread-safe or non-thread-safe PHP version, you can use the `Ts` input. It supports values `ts` and `nts`.
- To specify the libraries required for the extension, you can use the `Libraries` input. It supports a comma-separated list of library names.
- To specify additional arguments to pass to the `configure` script, you can use the `Args` input. It supports a string value.

```powershell
Invoke-PhpBuildExtension -ExtensionUrl https://github.com/xdebug/xdebug `
                         -ExtensionRef 3.4.5 `
                         -PhpVersion 8.4 `
                         -Arch x64 `
                         -Ts nts `
                         -Libraries "zlib" `
                         -Args "--with-xdebug"
```

To build an extension from a local source, run `Invoke-PhpBuildExtension` from the extension’s source directory and omit the `ExtensionUrl` and `ExtensionRef` inputs.

```powershell
# cd to xdebug source directory, and then run
Invoke-PhpBuildExtension -PhpVersion 8.4 -Arch x64 -Ts nts -Libraries "zlib" -Args "--with-xdebug"
```

It should produce the extension builds in a directory named `artifacts` in the current directory.

## License

The scripts and documentation in this project are released under the [MIT License](LICENSE)
