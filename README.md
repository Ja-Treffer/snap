# Snap — Flutter demo

Itchi Flutter Session 1–3 的完整落地：四个页面（List / Detail / Add / Settings）、JSON 本地持久化、相机与相册选图、三语本地化（EN / 简体 / 繁體）。

## 目录

```
lib/
  Models/       纯数据类（JournalEntry）
  Component/    可复用 UI（JournalCard）
  Pages/        一页一目录：Page + PageController
  Utils/        存储、设置、格式化、AppScope
  l10n/         ARB 与生成的 AppLocalizations
docs/
  PROJECT_SPEC.md     工程契约（需求 / AC / 页面契约 / 边界 / 债务台账）
  rag/                检索用文档库（架构 / 数据 / 页面 / i18n / 权限 / 构建 / 坑）
  DEVELOPMENT.md      日常开发流程
  SESSION3_PLAN.md    里程碑与实测记录
  SESSION3_NOTES.md   通用做法 vs Flutter 落法
test/           30 个用例（flow / session3 / photo_store / models / journal_card）
```

## 跑起来

```bash
flutter pub get
flutter gen-l10n           # 改了 ARB 之后
flutter analyze && flutter test
flutter run -d windows     # 或 -d chrome / emulator-5554
```

Android 需要 `compileSdk = 37`（`permission_handler_android` 要求）；相册走系统 Photo Picker。

## 约定

- 文案一律走 `AppLocalizations`，不硬编码在 widget 里。
- 照片只存文件名，文件放在 `<documents>/photos/`，由 `PhotoStore` 管理。
- 分层规则、验收标准、技术债台账见 [docs/PROJECT_SPEC.md](docs/PROJECT_SPEC.md)。
- 遇到问题先查 [docs/rag/07-pitfalls.md](docs/rag/07-pitfalls.md)。
