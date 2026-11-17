# CHANGELOG · RAG 文档集

只记“知识库层面”的变化，代码提交历史看 `git log`。

## 2026-11-17 · Session 4（图标 / 主题 / 版本 / 原生插件）

**代码**：

- `flutter_launcher_icons` 生成 Android 5 档 + iOS 22 个图标文件，源图 `assets/icon/icon_1024.png`。
- 新 `lib/Utils/app_theme.dart`：课件的五个色值进 `ColorScheme`，AppBar 绿底白字，Card 取 surface；
  `main.dart` 弃用旧 `seedColor`。
- `package_info_plus` + `Models/AppVersion.dart`；Settings 新增 About 段与 key `appVersion`；
  pubspec 版本 `1.0.0+1 → 1.1.0+2`。
- 新 `lib/Utils/duo_layout.dart`（`DuoBridge` 接缝 + `DuoLayoutController`），接入
  `itchi_flutter_duo_layout`；全局 `navigatorKey`；三个页面按 `railActive` 关掉自带返回键；
  Home 支持双栏。
- 新 `test/session4_test.dart`（10 例）。`flow_test.dart` 的 AC-5 加 `scrollUntilVisible`。

**文档**：`PROJECT_SPEC.md` 升 v2.6（§8 视觉规范重写、新增 §15）；新增 `SESSION4_NOTES.md`；
`rag/03`、`rag/06`、`rag/07` 各补一条。

**验收**：`flutter analyze` 干净；`flutter test` 43/43；`flutter build web --release` 通过；
`flutter build apk --debug` 通过且图标已换。

## 2026-11-10 · 建库 + 技术债清理

**新建**：README + 01~07 共八篇，随 Session 3（权限 / 照片 / 存储 / i18n / Challenge）收尾一次性建立。

**同一批落地的代码变化**（对应文档已同步）：

- 孤儿照片治理：`PhotoStore.deleteUnreferenced` + `HomePageController.purgeOrphanPhotos`；启动、Add 页取消返回、点移除照片三处触发。
- `PhotoStore.delete` 失败重试一次（Windows 句柄延迟释放）。
- 卡片缩略图加 `cacheWidth`，避免按原图解码。
- Add 页注入 `imagePicker` 真正生效（此前字段被硬编码覆盖），可测。
- 新增 `test/photo_store_test.dart`：AC-S3-13 回收、AC-S3-14 放弃选图、AC-S3-15 移除照片。
- dev 依赖补 `permission_handler_platform_interface` + `plugin_platform_interface`，测试里给权限平台一个全同意的假实现。

**验收**：`flutter analyze` 干净；`flutter test` 30/30；模拟器实测“选图 → 返回”不留文件、用户已有条目及其照片保留。

## 待办（下一次该顺手做的）

- `docs/PROJECT_SPEC.md` 的 AC 编号与 `test/` 里的新用例（AC-S3-13..15）对齐一次。
- `usedBytes` 与 `sizeInBytes` 的取整口径在文档里只写了一次，改口径记得同时改 04 篇。
