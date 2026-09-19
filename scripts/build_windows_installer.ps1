param(
    [switch]$SkipFlutterBuild,
    [string]$ReleaseDirectory,
    [string]$CompilerPath
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$portableFlutter = 'D:\toolchains\flutter\bin\flutter.bat'
$flutter = if (Test-Path -LiteralPath $portableFlutter) { $portableFlutter } else { 'flutter' }
$versionLine = Get-Content -LiteralPath (Join-Path $projectRoot 'pubspec.yaml') -Encoding UTF8 |
    Where-Object { $_ -match '^version:\s*' } | Select-Object -First 1
if ($versionLine -notmatch '^version:\s*([0-9]+\.[0-9]+\.[0-9]+)') {
    throw 'Cannot read app version from pubspec.yaml'
}
$releaseVersion = $Matches[1]
$releaseDir = if ([string]::IsNullOrWhiteSpace($ReleaseDirectory)) {
    Join-Path $projectRoot 'build\windows\x64\runner\Release'
} else {
    $ReleaseDirectory
}
$distDir = Join-Path $projectRoot 'dist'

if (-not $SkipFlutterBuild) {
    Push-Location -LiteralPath $projectRoot
    try {
        & $flutter build windows --release
        if ($LASTEXITCODE -ne 0) { throw 'Windows release build failed' }
    } finally {
        Pop-Location
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $releaseDir 'CalorieRecord.exe'))) {
    throw 'Windows release files were not found'
}

$isccCandidates = @(
    $CompilerPath,
    (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),
    (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe'),
    'D:\toolchains\InnoSetup\ISCC.exe',
    'C:\ProgramData\chocolatey\bin\iscc.exe'
)| Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
$iscc = $isccCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if ($null -eq $iscc) { throw 'Inno Setup 6 compiler was not found' }
New-Item -ItemType Directory -Path $distDir -Force | Out-Null

& $iscc "/DMyAppVersion=$releaseVersion" "/DMySourceDir=$releaseDir" "/DMyOutputDir=$distDir" `
    (Join-Path $projectRoot 'installer\CalorieRecord.iss')
if ($LASTEXITCODE -ne 0) { throw 'Installer compilation failed' }
Write-Host "Installer created: dist\CalorieRecord-Setup-v$releaseVersion.exe"
