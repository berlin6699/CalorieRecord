# CalorieRecord（能量收支）

一款离线运行的 Android 健身饮食与能量收支记录 App。数据只保存在设备本地，支持三类训练日目标、菜谱管理、餐食和运动记录、7/30/90 天趋势以及 JSON 备份恢复。热量按净增加/净缺口展示，三大营养素按每天保存的目标快照判断达标情况。

## 开发与构建

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release
```

在 Windows 上调试 Android 版需要 Flutter SDK、Android Studio、Android SDK 和 Android Emulator。运行 `flutter doctor -v` 可检查环境。

本机已在 `D:\toolchains` 准备好便携式 Flutter、JDK、Android SDK 和 `EnergyBalance_API36` 模拟器。直接运行：

```powershell
.\scripts\run_android.ps1
```

脚本会启动可见的虚拟手机并进入 `flutter run`，可在终端按 `r` 热重载。重新检查并生成 APK 可运行 `.\scripts\build_apk.ps1`。

## 菜谱批量导入

把餐食图片或营养标签交给 Codex，并要求它按照 `examples/recipes.example.json` 的结构生成 UTF-8 JSON。然后在 App 的“菜谱”页点击右上角导入按钮。

- `schemaVersion` 固定为 `1`。
- 每份菜谱必须包含名称、每份说明、能量、碳水、蛋白质和脂肪。
- 数值单位固定为 kcal 和 g，必须大于或等于零。
- 导入前可选择覆盖或跳过同名菜谱。

完整备份文件由 App 自动生成，不应手动修改；恢复时会整体替换当前数据。
