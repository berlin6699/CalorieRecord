$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$portableFlutter = 'D:\toolchains\flutter\bin\flutter.bat'
$flutter = if (Test-Path -LiteralPath $portableFlutter) {
    $portableFlutter
} else {
    'flutter'
}

$portableJava = 'D:\toolchains\jdk17\jdk-17.0.20.1+1'
if (Test-Path -LiteralPath $portableJava) {
    $env:JAVA_HOME = $portableJava
}
$portableAndroidSdk = 'D:\toolchains\android-sdk'
if (Test-Path -LiteralPath $portableAndroidSdk) {
    $env:ANDROID_HOME = $portableAndroidSdk
    $env:ANDROID_SDK_ROOT = $portableAndroidSdk
}

Push-Location -LiteralPath $projectRoot
try {
    & $flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }
    & $flutter analyze
    if ($LASTEXITCODE -ne 0) { throw 'flutter analyze failed' }
    & $flutter test
    if ($LASTEXITCODE -ne 0) { throw 'flutter test failed' }
    & $flutter build apk --release
    if ($LASTEXITCODE -ne 0) { throw 'Android release build failed' }
    & $flutter build windows --release
    if ($LASTEXITCODE -ne 0) { throw 'Windows release build failed' }

    $dist = Join-Path $projectRoot 'dist'
    New-Item -ItemType Directory -Path $dist -Force | Out-Null
    Copy-Item -LiteralPath 'build\app\outputs\flutter-apk\app-release.apk' `
        -Destination (Join-Path $dist 'CalorieRecord-Android-v1.0.8.apk') -Force
    Compress-Archive -Path 'build\windows\x64\runner\Release\*' `
        -DestinationPath (Join-Path $dist 'CalorieRecord-Windows-x64-v1.0.8.zip') -Force
    Write-Host "Release files created in $dist"
} finally {
    Pop-Location
}
