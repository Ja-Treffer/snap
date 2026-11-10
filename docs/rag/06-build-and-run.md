# 06 · 构建与运行

一句话：**analyze 干净 → test 全绿 → 才 build；模拟器是主人的机器，不擅自开。**

## 日常三连

```powershell
cd E:\flutter\demo_pages
flutter analyze
flutter test
```

两者都绿再谈构建。`flutter analyze` 有 issue 时不要继续往下做——本仓库的 lint 是干净的，一旦有 issue 说明是新引入的。

## 构建

| 目标 | 命令 | 产物 |
| --- | --- | --- |
| Android | `flutter build apk --debug` | `build\app\outputs\flutter-apk\app-debug.apk` |
| Web | `flutter build web --release` | `build\web\`（起静态服务即可看） |
| Windows | `flutter build windows --debug` | `build\windows\x64\runner\Debug\demo_pages.exe` |

### compileSdk 37

`android/app/build.gradle.kts` 里写死 `compileSdk = 37`，因为 `permission_handler_android` 的 AAR 元数据要求至少 37。本机 SDK 目录是 `E:\Android\Sdk\platforms\android-37.0`（名字带 `.0`，`sdkmanager` 认不出来但 Gradle 能用）。升级依赖前先确认还需不需要这一行。

### Windows 桌面 + 插件

带插件的工程在 Windows 上构建需要符号链接权限（开发者模式）。本机注册表已置 `AllowDevelopmentWithoutDevLicense=1`，但当前登录令牌没有 `SeCreateSymbolicLinkPrivilege`，所以 Windows 构建暂时不可靠；要在 Windows 上验证就走 Web。

### Gradle 缓存撞车

偶发 `java.lang.AssertionError: Could not close incremental caches in build\image_picker_android\kotlin\...`。修法：删 `build\<plugin>_android` 目录；`android/gradle.properties` 里已加 `kotlin.incremental=false` 兜底。

## 模拟器（只有主人说开才开）

```powershell
# 启动（gpu host 会让 qemu 自己退出，用 swiftshader_indirect）
emulator -avd RPClient_API36 -gpu swiftshader_indirect -no-boot-anim -no-snapshot-save

# 等开机
adb wait-for-device; adb shell getprop sys.boot_completed   # 等到 1

# 装 + 起
adb install -r build\app\outputs\flutter-apk\app-debug.apk
adb shell am start -n com.itchi.demo_pages/.MainActivity

# 截图
adb shell screencap -p /sdcard/s.png
adb pull /sdcard/s.png docs\shot.png
```

AVD 关键配置（`%USERPROFILE%\.android\avd\RPClient_API36.avd\config.ini`）：`hw.lcd.width=540`、`hw.lcd.height=1170`、`hw.lcd.density=210`、`showDeviceFrame=no`。窗口比屏幕还高就是这套参数被改回去了。

## Web 预览

```powershell
flutter build web --release
python -m http.server 8090 --bind 127.0.0.1 --directory build\web
chrome --app=http://127.0.0.1:8090/ --window-size=430,860
```

手机宽度截图：headless Chrome 有最小视口（约 500px），直接 `--window-size=420,880` 会按 800 排版再裁切。要么用 900×700 截，要么在 `build\web` 放一个 `<iframe src="/" width=420 height=880>` 的壳页再截。

## 编辑器

Cursor 3.27.12（`%LOCALAPPDATA%\Programs\cursor`，CLI `cursor.cmd` 已在 PATH）已装 Flutter 扩展，`.vscode\launch.json` 里有 Windows / Chrome / web-server(8090) / 单文件测试四套配置。F5 起热重载，等价于 `flutter run -d windows|chrome|web-server`。

## 最后核对

2026-11-10。
