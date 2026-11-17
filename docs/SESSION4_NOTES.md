# Session 4 教学笔记 · 图标 / 主题 / 版本 / 原生插件

对应课件 `document/Itchi_Flutter_Session4.pptx`（36 页）。
落地工程：`E:\flutter\demo_pages`（v2.6）。分支：`dev/yg`。

## 一句话总结

四段各解决一个问题：**图标**（一张源图生成全平台）、**主题**（一处定义、全站生效）、
**版本**（build 时写死、运行时读出）、**原生插件**（Dart 够不到的地方交给原生，但要有降级）。

## PART 01 · App icon

- 源图：`assets/icon/icon_1024.png`，1024×1024，RGBA。
- 配置（pubspec 末尾）：

```yaml
flutter_launcher_icons:
  image_path: "assets/icon/icon_1024.png"
  android: true
  ios: true
  remove_alpha_ios: true   # iOS 拒绝带 alpha 的图标
  min_sdk_android: 21
```

- 生成：`dart run flutter_launcher_icons`。
  产物：Android `mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png` 五档；iOS
  `Assets.xcassets/AppIcon.appiconset` 22 个文件。
- **不手改生成结果**：换图就换源图再跑一次。

## PART 02 · App theme

五个色值 → `lib/Utils/app_theme.dart`：

| 课件名 | 值 | M3 落点 |
|---|---|---|
| Primary | `#025928` | `colorScheme.primary` + AppBar 底色 |
| Secondary | `#F25D27` | `colorScheme.secondary` |
| Accent | `#D9653B` | `colorScheme.tertiary`（M3 没有 accent） |
| Surface | `#F2B29B` | `Card` 底色 + `surfaceContainerHighest` |
| Background | `#F2F2F2` | `colorScheme.surface` + `scaffoldBackgroundColor` |

- `ColorScheme.fromSeed(primary)` 给整套 onXxx 对比度兜底，再 `copyWith` 覆盖五个值。
- 纪律：页面里 **不许** `Color(0x…)`。全仓 grep 只剩 `app_theme.dart` 一处（AC-S4-01/02 守着）。
- 加 `AppBarTheme`（绿底白字）与 `CardThemeData(color: surface)`，否则 M3 默认色会把品牌色盖掉一半。

## PART 03 · App version

- pubspec `version: 1.1.0+2` → `1.1.0` 是 version，`2` 是 build number。
- 读法：`package_info_plus` 的 `PackageInfo.fromPlatform()`，读的是**构建时写进包里的值**，
  所以改了 pubspec 必须重新 build/run 才看得到。
- 本工程：`Models/AppVersion.dart`（纯数据）+ `SettingsPageController.refreshVersion()`，
  通过 `loadVersion` 参数注入，测试不用平台通道。
- Settings 显示：About 段 + key `appVersion`，文案走 ARB `settings_version{version,build}`。

## PART 04 · Native plugin

- 插件：`https://github.com/itchitechhk/itchi_flutter_duo_layout`（版本 0.1.0，iOS only）。
- pubspec：

```yaml
  itchi_flutter_duo_layout:
    git:
      url: https://github.com/itchitechhk/itchi_flutter_duo_layout.git
      ref: main
```

- 只用一层壳：`lib/Utils/duo_layout.dart`。全仓只有它 `import` 插件。
  - `DuoBridge`：接缝，测试塞假实现。
  - `DuoLayoutController.railActive`：平台真的把侧栏 Back 放上去了吗。
  - `DuoLayoutController.wantsTwoPanes(Size)`：hinge 说 fully open 且短边 ≥ 600 → 双栏；
    没有 hinge 时按尺寸兜底（短边 ≥ 600 且长边 ≥ 640）。
- 三个集成点：
  1. `DemoApp` 持有全局 `navigatorKey`，原生 Back → `maybePop()`。
  2. Detail / Add / Settings 的 AppBar：`automaticallyImplyLeading: !railActive`
     （不然用户看到两个返回键）。
  3. `HomePage`：双栏走两个独立滚动的列，卡片高度不用算。
- **降级是硬要求**：Android / Web / Windows / 测试环境全部走 `unsupportedPlatform`，
  代码不抛、界面照旧。`AC-S4-06/07` 守这条。

## 课后追加 · 背景图 + 透明度

课件里没有，是课后提的需求：**导入一张图当页面背景，并调它透出多少**。

- 存储：`AppSettings.backgroundImage`（只存**文件名**，图落在 `photos/`）+ `backgroundOpacity`（0.05–1.0，默认 0.35）。
- 导入：Settings → Background 选图，`PhotoStore.import` 复制进 `photos/`，换图时删上一张。
- 渲染：`MaterialApp.builder` 里垫 `BackgroundLayer`（`Image.file` + `AlwaysStoppedAnimation(opacity)`），
  同时 `AppTheme.light(transparentScaffold: true)` 让 Scaffold 透明，图从卡片缝隙透出来。
- 两个必须记住的点：
  1. 背景图存在 `photos/` 里，**孤儿清理的白名单必须带上它**，否则下次启动就被删。
  2. web 上没有 `dart:io`，`BackgroundLayer` 用 `kIsWeb` 跳过；能设置，但画面还是纯色。

## Checkpoint 对照

| 项 | 状态 | 证据 |
|---|---|---|
| 主屏显示新图标 | ✅ Android 已验（APK 内 xxhdpi 图即新图标）；iOS 未验证 | `docs/shot-s4-apk-icon.png` |
| 主题色全站生效 | ✅ | `docs/shot-s4-one-pane.png`、`shot-s4-two-pane.png` |
| Settings 显示版本、改后生效 | ✅ 代码 + 单测；改 pubspec 需重新 build | `AC-S4-05`、`build/web/version.json` |
| 插件：侧栏 Back / fold / 双栏 | ⚠️ Dart 侧完成并有测试；iOS 真机未验证 | `AC-S4-08/09/10`、§15.6 |
| 背景图 + 透明度（课后追加） | ✅ 逻辑与持久化有测试 | `AC-S4-11/12/13` |

## 踩到的坑

1. **改了 `version:` 忘记重新 `pub get` + build**：`build/web/version.json` 还是 1.0.0，
   第一眼以为插件读错了。教训：版本号改完必须重跑构建，光刷新页面没用。
2. **About 段把 `SettingsBack` 挤到折叠线以下**：`AC-5` 从「找不到按钮」变成失败。
   正确修法是测试里 `scrollUntilVisible`（真实用户也要滚），不是把 Back 挪上去。
3. **`DuoFoldSnapshot` 构造器是私有的**：测试里要用 `DuoFoldSnapshot.fromMessage({...})`
   伪造，别想 `const` 一个。
4. **iOS 26 之前**没有 fold API，插件会回 `osUnavailable`——那是正常值，不是 bug。

## 未验证 / 留给下一步

- iOS 模拟器上的侧栏与 fold（需要 macOS，见 spec §15.6）。
- Windows 桌面构建（插件工程的符号链接前置条件）。
- Android adaptive icon（源图主体满幅，前景层会被裁）。
