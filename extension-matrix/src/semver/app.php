<?php

require __DIR__ . '/vendor/autoload.php';

use Composer\Semver\Constraint\Constraint;
use Composer\Semver\VersionParser;

if ($argc < 3) {
    echo "Usage: php app.php '<constraint>' '<version1,version2,...>'\n";
    exit(1);
}

$constraint = $argv[1];
$versions = array_filter(explode(',', preg_replace('/\s+/', '', $argv[2])));

if(count($versions)) {
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
}