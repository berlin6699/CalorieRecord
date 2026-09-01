$ErrorActionPreference = 'Stop'

$FlutterSdk = 'D:\toolchains\flutter'
$AndroidSdk = 'D:\toolchains\android-sdk'
$JavaSdk = 'D:\toolchains\jdk17\jdk-17.0.20.1+1'

$env:JAVA_HOME = $JavaSdk
$env:ANDROID_HOME = $AndroidSdk
$env:ANDROID_SDK_ROOT = $AndroidSdk
$env:Path = "$FlutterSdk\bin;$AndroidSdk\platform-tools;$env:Path"

& "$FlutterSdk\bin\flutter.bat" pub get
& "$FlutterSdk\bin\flutter.bat" analyze
& "$FlutterSdk\bin\flutter.bat" test
& "$FlutterSdk\bin\flutter.bat" build apk --release

Write-Host 'APK 已生成：build\app\outputs\flutter-apk\app-release.apk'
