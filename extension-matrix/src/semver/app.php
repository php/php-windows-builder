<?php

require __DIR__ . '/vendor/autoload.php';

use Composer\Semver\Constraint\Constraint;
use Composer\Semver\VersionParser;

if ($argc < 3) {
    echo "Usage: php app.php '<file>' '<constraint>' '<version1,version2,...>'\n";
    exit(1);
}

$file = $argv[1];
if($file === 'composer.json') {
    $constraint = $argv[2];
} else if($file === 'package.xml') {
    $package_xml = $argv[2];
    $xml = simplexml_load_file($package_xml);
    $xml->registerXPathNamespace("p", "http://pear.php.net/dtd/package-2.0");
    $min = $xml->xpath("//p:php/p:min")[0] ?? null;
    $max = $xml->xpath("//p:php/p:max")[0] ?? null;
    $constraint = '';
    if($min) {
        $constraint .= '>=' . $min;
    }
    if($max) {
        $constraint .= ',<=' . $max;
    }
    $constraint = ltrim($constraint, ',');
} else {
    echo "File not found";
    exit(1);
}

$versions = array_filter(explode(',', preg_replace('/\s+/', '', $argv[3])));

if (count($versions)) {
    $versionParser = new VersionParser();
    $constraint = $versionParser->parseConstraints($constraint);

    $satisfiedVersions = [];
    foreach ($versions as $version) {
        $parsedVersion = new Constraint('=', $versionParser->normalize($version));
        if ($parsedVersion->matches($constraint)) {
            $satisfiedVersions[] = $version;
        }
    }

    echo implode(',', $satisfiedVersions);
} else {
    echo "No versions provided";
    exit(1);
}
