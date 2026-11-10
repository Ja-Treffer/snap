# CHANGELOG · RAG 文档集

只记“知识库层面”的变化，代码提交历史看 `git log`。

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
