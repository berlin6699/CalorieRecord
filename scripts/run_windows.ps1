$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$portableFlutter = 'D:\toolchains\flutter\bin\flutter.bat'
$flutter = if (Test-Path -LiteralPath $portableFlutter) {
    $portableFlutter
} else {
    'flutter'
}

Push-Location -LiteralPath $projectRoot
try {
    & $flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }
    & $flutter run -d windows
    if ($LASTEXITCODE -ne 0) { throw 'flutter run failed' }
} finally {
    Pop-Location
}
