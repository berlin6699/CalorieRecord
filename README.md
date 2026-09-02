# CalorieRecord（能量收支）

一款离线运行的 Android / Windows 健身饮食与能量收支记录 App。两个版本功能一致，数据只保存在本机。

## v1.0 功能

- 今日净能量：摄入 − 基础消耗 − 运动消耗，清楚展示热量增加或热量缺口。
- 营养目标：碳水、蛋白质和脂肪按早餐、午餐、晚餐、加餐分色显示完成度。
- 菜谱与记录：每份菜谱可添加图片；每日餐食显示餐次、份数、能量与三大营养素。
- 训练计划：建立减脂、增肌、维持或自定义周期，按计划独立统计净能量。
- 历史趋势：查看所选训练计划内的实际数据与当天目标趋势线。
- 身体数据：按日期记录 11 项体成分与代谢指标，并分别查看可视化趋势。
- 三类日目标：有氧日、力量日和休息日可分别设置营养目标。
- 本地优先：SQLite 离线存储，支持跨 Android / Windows 的 JSON 备份与恢复。
- 响应式界面：手机使用底部导航，Windows 宽屏自动使用侧边导航和多列布局。

预编译版本可从 [GitHub Releases](https://github.com/berlin6699/CalorieRecord/releases) 下载。

## 开发与构建

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release
flutter run -d windows
flutter build windows --release
```

Android 版需要 Flutter SDK、JDK、Android SDK 和 Android Emulator；Windows 版还需要 Visual Studio Build Tools 的“使用 C++ 的桌面开发”工作负载。运行 `flutter doctor -v` 可检查环境。

本机已在 `D:\toolchains` 准备好便携式 Flutter、JDK、Android SDK 和 `EnergyBalance_API36` 模拟器。直接运行：

```powershell
.\scripts\run_android.ps1
```

脚本会启动可见的虚拟手机并进入 `flutter run`，可在终端按 `r` 热重载。重新检查并生成 APK 可运行 `.\scripts\build_apk.ps1`。

启动 Windows 调试版：

```powershell
.\scripts\run_windows.ps1
```

同时生成 Android APK 与 Windows ZIP 发布包：

```powershell
.\scripts\build_release.ps1
```

## 菜谱批量导入

把餐食图片或营养标签交给 Codex，并要求它按照 `examples/recipes.example.json` 的结构生成 UTF-8 JSON。然后在 App 的“菜谱”页点击右上角导入按钮。

- `schemaVersion` 固定为 `1`。
- 每份菜谱必须包含名称、每份说明、能量、碳水、蛋白质和脂肪。
- 数值单位固定为 kcal 和 g，必须大于或等于零。
- 导入前可选择覆盖或跳过同名菜谱。

完整备份文件由 App 自动生成，不应手动修改；恢复时会整体替换当前数据。
v1.0.4 起，完整备份的结构版本为 4，并继续兼容恢复结构版本 1、2 和 3。菜谱图片会以 Base64 编码一并备份。
