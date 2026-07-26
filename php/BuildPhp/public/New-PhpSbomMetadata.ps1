function New-PhpSbomMetadata {
    <#
    .SYNOPSIS
        Generate bundled-component metadata for a PHP source ref.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $PhpVersion,
        [Parameter(Mandatory=$true)]
        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
        [string] $SourceDirectory,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $OutputPath
    )

    $config = Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\config\sbom.json') -Raw | ConvertFrom-Json
    $versionConfig = $config.php.PSObject.Properties[$PhpVersion]
    if($null -eq $versionConfig) {
        throw "PHP version $PhpVersion does not have bundled-component metadata"
    }

    $licenseText = Get-Content -LiteralPath (Join-Path $SourceDirectory 'LICENSE') -Raw
    if($licenseText -match 'The PHP License, version 3\.01') {
        $phpLicense = 'PHP-3.01'
    } elseif($licenseText -match 'Redistribution and use in source and binary forms') {
        $phpLicense = 'BSD-3-Clause'
    } else {
        throw 'Could not determine the PHP source license'
    }

    $excludedComponents = @($versionConfig.Value.exclude)
    $components = @($config.components | Where-Object { $_.name -notin $excludedComponents } | ConvertTo-Json -Depth 10 | ConvertFrom-Json)
    foreach($override in $versionConfig.Value.overrides.PSObject.Properties) {
        $component = $components | Where-Object { $_.name -eq $override.Name }
        if($null -eq $component) {
            throw "Unknown bundled component $($override.Name)"
        }
        foreach($property in $override.Value.PSObject.Properties) {
            $component | Add-Member -NotePropertyName $property.Name -NotePropertyValue $property.Value -Force
        }
    }

    $outputComponents = foreach($component in $components) {
        if(-not (Test-Path -LiteralPath (Join-Path $SourceDirectory $component.path))) {
            throw "Bundled component path $($component.path) does not exist"
        }

        $entry = [ordered]@{ name = $component.name }
        $componentVersion = ''
        if($component.PSObject.Properties.Name -contains 'version') {
            $entry.version = $component.version
            $componentVersion = $component.version
        }
        $entry.path = $component.path
        $entry.license = $component.license
        $entry.purl = $component.purl.Replace('{version}', $componentVersion)
        [PSCustomObject]$entry
    }

    $outputDirectory = Split-Path -Path $OutputPath -Parent
    if($outputDirectory -and -not (Test-Path -LiteralPath $outputDirectory)) {
        New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    }
    [ordered]@{
        license = $phpLicense
        components = @($outputComponents)
    } | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutputPath -Encoding utf8
}
