# Session 3 规划（v3.0 草案）

> **状态**：规划定稿（v3.0）。三项技术决策已由主人拍板（§9）。**M1 + M2 已交付并在模拟器实测通过**（见 §10），M3 起等待主人发话。
>
> **依据**：Session 1 大纲第 3 课「权限、相机/相册、本地存储、i18n」+ Session 2 已交付的 EduSnap 四页（内存数据）。
> **限制**：`E:\flutter\document` 里只有 Session 1 的 pptx 与 Session 2 的 pdf，**没有 Session 3 的课件**，所以本文是按大纲反推的规划，不是抄课件。每条都写了「建议 Prompt 原文」，主人可以直接拿去当课件用。

---

## 1. Session 3 结束时的目标 Demo

> **加一张照片 → 杀掉进程 → 重开还在 → 在 Settings 切中文 → 整个界面变中文，重开仍是中文。**

三个能力缺一不可：**持久化**（数据活过进程）、**设备能力**（真的能拍照/选图）、**i18n**（界面语言可切且记住）。

---

## 2. 范围

### 2.1 In scope

| # | 能力 | 说明 |
|---|---|---|
| 1 | 模型扩展 | `JournalEntry` 增加 `String? photoPath`（可空：允许纯文字条目） |
| 2 | 本地持久化 | 条目写入应用私有目录的 `journal.json`；启动读、增删改后写；原子写（tmp + rename） |
| 3 | 图片落盘 | 选中的图片**拷贝**进应用目录 `photos/`，条目只存相对文件名（不存临时路径） |
| 4 | 相机 / 相册 | `image_picker`：拍一张 或 从相册选一张；取消、拒绝权限都要能优雅返回 |
| 5 | 图片显示 | 列表左侧缩略图、Detail 顶部大图；文件缺失/损坏降级为占位图 |
| 6 | i18n | `flutter_localizations` + ARB：英文（默认）+ 简体中文，**全部界面文案**走 l10n key |
| 7 | 语言切换 | Settings 里切换语言，立即生效并持久化（重启仍是该语言） |
| 8 | 真 Settings | 语言选择、清空全部数据（二次确认）、版本号 |
| 9 | 生命周期落盘 | `AppLifecycleListener` 在 `paused` 时补写一次，防异常退出丢数据 |

### 2.2 Out of scope（写清楚，避免顺手加进来变技术债）

- 云同步 / 多设备 / 账号体系。
- 图片裁剪、滤镜、多图上传、压缩策略调优（先原样拷贝，尺寸问题记台账）。
- 数据库（sqflite / drift）：条目量在千级以内，JSON 文件足够。
- iOS 真机实测（本机无 Mac）：只保证代码与 Info.plist 声明正确，标注"未验证"。
- 主题切换、深色模式、排序、搜索（Session 4 再说）。

---

## 3. 技术选型（含被否决的方案）

| 需求 | 方案 A | 方案 B | 采用 | 理由 |
|---|---|---|---|---|
| 条目存储 | JSON 文件（`path_provider` + `dart:io`） | sqflite | **A** | 图片本来就在文件系统，条目 JSON 放同目录最一致；sqflite 对千级数据无收益，还多一套 migration |
| 偏好存储 | `shared_preferences` | 塞进同一个 JSON | **A（仅偏好）** | 语言这类单值 flag 用 prefs 最省事，且不会因为条目 JSON 损坏而丢语言设置 |
| i18n | `gen-l10n` + ARB | 手写 `Map<String, String>` | **A** | 官方生成给类型安全（`AppLocalizations.of(context)!.listTitle`），拼错编译期就报；手写 Map 漏 key 只有运行时才发现 |
| 选图 | `image_picker` | `camera` 插件 | **A** | 相册+相机一个包搞定，官方维护，Web 也支持；`camera` 只做预览/拍照，相册还得再找包 |
| 状态管理 | 沿用 `ChangeNotifier` + 构造注入 | Provider / Riverpod / Bloc | **A** | 教学阶段引入容器框架会掩盖 MVC 本身；页面只有 4 个、依赖一条线，构造注入足够。**何时该换**：出现跨页共享或 3 层以上传递时再评估 |
| 图片路径 | 存绝对路径 | 存文件名 + 运行时拼目录 | **B** | 应用沙盒路径在重装/升级后会变（iOS 尤甚），绝对路径必失效 |

依赖清单（M2 统一装，版本以 `pub` 解析为准）：

```yaml
dependencies:
  image_picker: ^1.1.2        # 相机 + 相册
  path_provider: ^2.1.4       # 应用私有目录
  shared_preferences: ^2.3.2  # 语言偏好
  intl: ^0.19.0               # 日期格式化 + l10n 依赖
  flutter_localizations:      # SDK
    sdk: flutter
```

---

## 4. 落位到现有分层（改哪些文件）

| 文件 | 动作 | 内容 |
|---|---|---|
| `lib/Models/JournalEntry.dart` | 改 | `+String? photoPath`；`toJson()` / `factory fromJson`；`copyWith` 增加 `photoPath` |
| `lib/Utils/journal_store.dart` | 新增 | `JournalStore`：`load()` / `save(List<JournalEntry>)`，原子写、JSON 编解码、异常兜底（坏文件 → 备份为 `.bak` 后返回空列表） |
| `lib/Utils/photo_store.dart` | 新增 | `Future<String> importPhoto(String sourcePath)`：拷贝进 `photos/`、返回文件名；`File? resolve(String? name)`；`deleteUnused(...)` |
| `lib/Utils/app_prefs.dart` | 新增 | 语言、将来别的 flag（读写 `shared_preferences`） |
| `lib/Pages/HomePage/HomePageController.dart` | 改 | `load()` 改走 `JournalStore`；`add/replace/remove` 后 `await save` |
| `lib/Pages/Add/AddPage.dart` + Controller | 改 | 加「拍照 / 从相册选」两个按钮 + 预览 + 清除；`buildEntry()` 带上 `photoPath` |
| `lib/Component/JournalCard/JournalCard.dart` | 改 | `leading` 加 48×48 缩略图（`ClipRRect` + `Image.file`），无图时用图标占位 |
| `lib/Pages/Detail/DetailPage.dart` | 改 | 顶部大图（可点开全屏，可选）；编辑时能换图 |
| `lib/Pages/Settings/SettingsPage.dart` | 重写 | 语言（System / English / 简体中文）、清空数据（二次确认）、版本号 |
| `lib/l10n/app_en.arb`、`app_zh.arb` | 新增 | 全部文案；`l10n.yaml` 指定 arb 目录与输出 |
| `lib/main.dart` | 改 | `localizationsDelegates` / `supportedLocales` / `locale`（来自 AppPrefs）、`MaterialApp.onGenerateTitle` |
| `android/app/src/main/AndroidManifest.xml` | 改 | `<uses-permission android:name="android.permission.CAMERA"/>`；**不要**手写 `READ_MEDIA_IMAGES`（Android 13+ 走 Photo Picker，声明了反而会被审核问） |
| `ios/Runner/Info.plist` | 改 | `NSCameraUsageDescription`、`NSPhotoLibraryUsageDescription`、`NSPhotoLibraryAddUsageDescription` |
| `test/` | 改 + 新增 | 现有 16 例要跟着文案 key 迁移；新增存储、图片降级、i18n 切换用例 |

---

## 5. 里程碑（6 步，每一步都能单独运行、单独验收）

> 严格按这个顺序，**一步一停**；每步收尾：`flutter analyze` 零 issue → `flutter test` 全绿 → 截图或行为录证 → 主人点头才进下一步。

**M1 · 持久化骨架（不碰图片）**
- 改模型加 `toJson/fromJson`；写 `JournalStore`；`HomePageController.load/save` 接上。
- 验收：加一条 → 完全杀掉 app → 重开 → 条目还在；手动把 `journal.json` 改坏 → 重开不崩、备份成 `.bak`。
- 建议 Prompt：`Persist the journal entries to a local JSON file under the app documents directory. Load on startup, save after every add/edit/delete. Use atomic write (temp file + rename) and recover from a corrupt file by backing it up. Keep the JournalEntry model free of any file access code.`

**M2 · 依赖与权限（只装不做）**
- 装 4 个包，写 `l10n.yaml` 占位，补两处权限声明，`flutter pub get` + `build apk --debug` 通过。
- 验收：APK 能装能跑，`flutter analyze` 干净；不写任何业务逻辑。
- 理由：把"环境类失败"和"代码类失败"分开，别让权限问题混在业务 bug 里。

**M3 · 选图**
- Add 页加两个按钮（拍照/相册）→ `image_picker` → `photo_store.importPhoto()` → `entry.photoPath`。
- 验收：取消选择不崩；拒绝权限弹一次说明；选完 Add 页出现预览；保存后条目带图。
- 建议 Prompt：`Update AddPage to attach a photo: a "Take photo" and a "Pick from gallery" button using image_picker. Copy the picked file into the app documents "photos" directory and keep only the file name in JournalEntry.photoPath. Handle cancel and permission denial without crashing.`

**M4 · 显示与降级**
- 卡片缩略图、Detail 大图、文件缺失显示占位。
- 验收：手删 `photos/` 里一张 → 列表与详情显示占位而不是红屏。

**M5 · i18n**
- 抽全部硬编码文案到 ARB（英 + 中）；`Settings` 加语言切换；`AppPrefs` 持久化；启动按 prefs 决定 `locale`。
- 验收：切中文 → 四页文案全变；重启仍是中文；切英文回来正常；现有 16 个测试迁移后全绿。
- **这一步代价最大**：所有 `find.text('List')` 都会失效，测试要改成 `find.text(l10n.listTitle)` 或用 key。

**M6 · 打磨**
- Settings 清空数据（二次确认 + 同时删照片）、`AppLifecycleListener` 在 `paused` 落盘、错误提示（存储失败/权限拒绝/磁盘满）、补测试。

---

## 6. 验收标准草案（AC，定稿时会重编号）

| ID | 场景 | 期望 |
|---|---|---|
| AC-S3-1 | 首启无数据文件 | 显示空态，不崩不写脏文件 |
| AC-S3-2 | 新增条目后强杀进程 | 重开后条目仍在（含照片） |
| AC-S3-3 | `journal.json` 内容非法 | 备份为 `.bak`，以空列表启动，界面提示过一次 |
| AC-S3-4 | 保存时磁盘/写权限失败 | 界面出错误提示，内存状态不丢 |
| AC-S3-5 | 拍照/相册取消 | 回到 Add 页，原有字段不丢 |
| AC-S3-6 | 拒绝权限 | 提示一次，可重试，不崩 |
| AC-S3-7 | 图片文件被删 | 列表与详情的缩略图位置显示占位图 |
| AC-S3-8 | 切换语言 | 立即生效，四页文案同步变化，不需重启 |
| AC-S3-9 | 重启后语言 | 保持上次选择 |
| AC-S3-10 | 删除条目 | 条目消失且对应照片文件被清理（不留孤儿文件） |
| AC-S3-11 | 清空数据 | 二次确认后条目与照片全清，语言设置保留 |
| AC-S3-12 | `paused` 生命周期 | 触发一次落盘（日志可观测） |
| AC-S3-13 | 静态检查 | `flutter analyze` → No issues found! |
| AC-S3-14 | 测试 | `flutter test` 全绿（现有 16 + 新增 ≥6） |

---

## 7. 预判的坑（先写下来，做到时逐条核对）

1. **临时路径陷阱**：`image_picker` 给的是缓存目录路径，系统随时会清 → **必须立刻 copy 到应用目录**，条目只存文件名。
2. **重装/升级后路径变化**：iOS 沙盒容器路径会变，存绝对路径必炸 → 存文件名，运行时用 `getApplicationDocumentsDirectory()` 拼。
3. **JSON 时间**：用 `toIso8601String()` / `DateTime.parse()`；`toString()` 不可逆。
4. **原子写**：先写 `journal.json.tmp` 再 `rename`（Windows 上 rename 到已存在文件要 `delete` 或 `File.rename` 覆盖策略要验），避免半截文件。
5. **Android 13+ 权限**：Photo Picker 不需要 `READ_MEDIA_IMAGES`；相机需要 `CAMERA`（`image_picker` 内部已用 `ACTION_IMAGE_CAPTURE`，部分机型仍要求声明）。
6. **模拟器没有照片**：`adb push pic.jpg /sdcard/Pictures/` 再 `adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/pic.jpg`，否则相册是空的。
7. **i18n 与测试**：`gen-l10n` 生成在 `.dart_tool/`，`flutter test` 前会自动生成；测试里取 `AppLocalizations` 需要 `Localizations` 已加载（记得 `pumpAndSettle`）。
8. **语言切换的刷新**：`MaterialApp.locale` 变化会重建整棵树，但要确保 `locale` 来自一个会通知的 controller（否则切了不刷新）。
9. **孤儿照片**：删条目/清空时要同步删文件，否则 `photos/` 越积越多（记台账，M6 处理）。
10. **Web 端差异**：`image_picker` 在 Web 返回 `blob:` 地址，`dart:io` 不可用 → 若继续保留 Web 跑道，`photo_store` 要分支（或 Web 上禁用图片，记台账）。

---

## 8. 技术债台账（本轮先认下来）

| 债务 | 原因 | 偿还时机 |
|---|---|---|
| 无 schema 版本号 | `journal.json` 直接读写，字段变更会丢旧数据 | 需要迁移时加 `version` 字段 |
| 图片不压缩、不做缩略图缓存 | 先跑通 | 条目多了明显卡顿时 |
| iOS 未实测 | 无 Mac | 有 Mac 时补 |
| Web 图片能力可能受限 | `dart:io` 在 Web 不可用 | 若要交付 Web 版 |
| 语言切换不跟随系统变化实时更新 | 只在启动读一次 | 需要时监听 `didChangeLocales` |

---

## 9. 决策记录（主人 2026-11-03 已拍板）

| 决策 | 选择 | 备注 |
|---|---|---|
| 持久化 | **JSON 文件 + `path_provider`** | `journal.json` 存条目；`shared_preferences` 只放语言这类 flag |
| i18n | **`gen-l10n` + ARB** | 英（默认）+ 简中；M5 需迁移现有 16 个测试的文案断言 |
| 推进节奏 | **本次只做 M1 + M2，做完停下验收** | M3（选图）起等主人再发话 |

---

## 10. 实测记录（M1 + M2 已交付，2026-11-03）

### 10.1 代码落点

| 文件 | 内容 |
|---|---|
| `lib/Models/JournalEntry.dart` | `+String? photoPath`；`toJson()`；`factory fromJson`（字段缺失/日期非法都降级不抛）；`copyWith` 支持 `photoPath` |
| `lib/Utils/journal_store.dart` | `JournalStore`：`exists()` / `load()` / `save()`；原子写（`.tmp` → delete → rename）；坏文件隔离成 `journal.json.bak-<ms>`；`JournalStore.inMemory()` 供 widget 测试用 |
| `lib/Pages/HomePage/HomePageController.dart` | 注入 `JournalStore`；`load()` 走磁盘；首次运行才播种样例（用 `exists()` 判断，避免删空后重开又长回来）；增删改后 `unawaited(_persist())` |
| `lib/Pages/HomePage/HomePage.dart` | 新增可选 `controller` 参数（DI 缝），自己创建的 controller 才负责 `dispose` |
| `lib/main.dart` | `DemoApp` 新增可选 `home`（仅测试用） |
| `test/journal_store_test.dart` | 2 例：临时目录真实读写往返；无平台通道自动降级内存 |
| `test/flow_test.dart` | `_pumpApp` 改为注入 `JournalStore.inMemory()`（真实文件 IO 在 widget 测试的假时钟下永远完不成） |
| `android/app/src/main/AndroidManifest.xml` | `CAMERA` 权限 + `uses-feature camera required=false`；**不声明** `READ_MEDIA_IMAGES` |
| `android/gradle.properties` | `kotlin.incremental=false`（见 10.3） |

### 10.2 模拟器实测（`emulator-5554`，540×1170）

| 步骤 | 结果 | 证据 |
|---|---|---|
| 首次启动 | 三条样例出现，`app_flutter/journal.json` 651 B 写出 | `docs/m1-1.png` |
| 新增一条 → `am force-stop` → 重启 | 条目仍在最上方，未重复播种（4 条） | `docs/m1-4.png` + `journal.json` 内容 |
| 把 `journal.json` 改成 `{broken json` → 重启 | 不崩；坏文件被改名 `journal.json.bak-1793708756740`；界面显示 `No entries yet` | `docs/m1-5-corrupt.png` |
| 放回好文件 → 重启 | 4 条恢复 | `docs/m1-6-restored.png` |

静态与测试：`flutter analyze` → **No issues found!**；`flutter test` → **18/18 通过**（16 个旧例 + 2 个存储用例）；`flutter build apk --debug` → 通过（19.7 s）。

### 10.3 本轮踩坑（已同步进 flutter-dev 技能）

1. **widget 测试里不能用真实文件 IO**：`pumpAndSettle` 配假时钟，真实 `File.exists()` 的 Future 永不完成 → 转圈转到超时。解法是给 store 一个 `inMemory` 构造并注入。
2. **Kotlin 增量编译缓存报错**：`Could not close incremental caches in build\image_picker_android\kotlin\...` → 在 `android/gradle.properties` 加 `kotlin.incremental=false`，并删掉对应 `build/<plugin>_android` 目录。
3. **Windows 桌面端加插件要符号链接**：`Building with plugins requires symlink support`。已通过 UAC 把 `AllowDevelopmentWithoutDevLicense=1` 写进 `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock`，但**当前登录令牌仍未拿到 SeCreateSymbolicLinkPrivilege**，需注销重登才生效 → 本阶段验证一律走 Android 模拟器与 Web，Windows 构建暂不保证。
4. **模拟器两次自行退出**（"飞天"）：`-gpu host` 下 qemu 会挂；改 `-gpu swiftshader_indirect` 后稳定（慢一点但能跑）。
5. **工程没有 ios/ 目录**：`demo_pages` 创建时只给了 `android,web,windows`，计划里的 Info.plist 三条权限无从落笔 → 记入台账，真要 iOS 时先 `flutter create --platforms=ios .`。
6. **`adb shell input text`** 不接受空格（要写 `%s`），所以实测里标题被截成 `Persisted`。

### 10.4 台账补充

- iOS 平台目录缺失（见 10.3-5）。
- Windows 桌面构建在本机不可用（symbolic link 权限），需注销重登后再验。
- 播种逻辑用"文件是否存在"判断：用户手动把数据文件全删光后重启，样例会再出现一次 —— 接受。

### 10.5 校验规则调整（主人 2026-11-03 20:34 指示）

原规则「标题必填」改为「**只拦截完全空白的表单**」：

| 场景 | 处理 |
|---|---|
| 标题空 + 备注空 | 弹 `Nothing to save`（key `emptyEntryDialog`），不 pop、不落库 |
| 标题空 + 备注有内容 | **不拦截**，标题落常量 `AddPageController.untitled = 'Untitled'` |
| 标题有内容 + 备注空 | 正常保存（备注空字符串） |

理由：照片日志的常见用法是「先写一句话，标题懒得取」，为标题逼用户打字是无效摩擦；而完全空白保存只会产生一条空卡片，属实垃圾数据。

实现落点：`lib/Pages/Add/AddPageController.dart`（`hasNote` / `isBlank` / `untitled` / `buildEntry()` 解析标题）+ `lib/Pages/Add/AddPage.dart`（`_save()` 判 `isBlank`、对话框改 `_showEmptyEntry()`）。测试 AC-7 改写 + 新增 AC-7b。

台账：`Untitled` 目前是硬编码英文，M5（gen-l10n）时必须搬进 ARB 的 `entryUntitled`。
