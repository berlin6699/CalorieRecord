$ErrorActionPreference = 'Stop'

$FlutterSdk = 'D:\toolchains\flutter'
$AndroidSdk = 'D:\toolchains\android-sdk'
$JavaSdk = 'D:\toolchains\jdk17\jdk-17.0.20.1+1'
$AvdName = 'EnergyBalance_API36'

foreach ($requiredPath in @($FlutterSdk, $AndroidSdk, $JavaSdk)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "缺少开发工具：$requiredPath"
    }
}

$env:JAVA_HOME = $JavaSdk
$env:ANDROID_HOME = $AndroidSdk
$env:ANDROID_SDK_ROOT = $AndroidSdk
$env:Path = "$FlutterSdk\bin;$AndroidSdk\platform-tools;$AndroidSdk\emulator;$env:Path"

$adb = Join-Path $AndroidSdk 'platform-tools\adb.exe'
$emulator = Join-Path $AndroidSdk 'emulator\emulator.exe'
$connected = & $adb devices | Select-String 'emulator-\d+\s+device'

if (-not $connected) {
    Write-Host "正在启动 Android 模拟器 $AvdName ..."
    Start-Process -FilePath $emulator -ArgumentList @(
        '-avd', $AvdName,
        '-no-snapshot-load'
    )
    & $adb wait-for-device
    do {
        Start-Sleep -Seconds 2
        $booted = (& $adb shell getprop sys.boot_completed 2>$null).Trim()
    } while ($booted -ne '1')
}

Write-Host '模拟器已就绪，启动 Flutter 热重载调试...'
& "$FlutterSdk\bin\flutter.bat" run -d emulator-5554
