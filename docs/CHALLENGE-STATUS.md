# 挑战完成情况核对

对课件 Session 1–4 的「Session N output」与「Challenge」逐条核对，证据都是本仓库里能复查的东西。
核对日期：2026-11-17。

## Session 1 · 环境 / 工程 / 结构 / 架构 / 代码管理

| 课件要求 | 状态 | 证据 |
|---|---|---|
| Cursor IDE 装好 | ✅ | `%LOCALAPPDATA%\Programs\cursor\Cursor.exe`，CLI 包装在 `...\resources\app\bin\cursor.cmd` |
| Cursor CLI（`agent --version`） | ⚠️ 未装 | PATH 里没有 `agent` / `cursor-agent`，`~\.cursor\cli` 不存在；终端直接跑 `flutter` / `git` |
| Flutter 装好、doctor 无红 | ✅ | Flutter 3.47.9 stable；`flutter analyze` 无 issue |
| 运行目标可用 | ✅ | web / windows / android 三个目标都构建通过（见 §Session 4） |
| 工程能跑 | ✅ | 工程名 `demo_pages`（课件写 `edusnap`，同一个四页 Demo）；`flutter build windows --debug` 成功 |
| lib 下有 Models / Component / Pages / Utils | ✅ | `lib/{Models,Component,Pages,Utils}`，另有 `l10n`（Session 3 生成） |
| 懂 Model / View / Controller 分工 | ✅ | `docs/PROJECT_SPEC.md` §4「分层约定」有归属表与文件清单 |
| 私有仓库已克隆 | ✅ | `origin = https://github.com/Ja-Treffer/snap.git` |
| 个人 dev 分支已推 | ✅ | 分支 `dev/yg`，与 `main` 同步 |
| SourceTree | ⚠️ 未装 | 全程用 git CLI；提交历史可在远端查看 |

## Session 2 · UI / 导航 / 表单

对应 `docs/PROJECT_SPEC.md` 的 AC-1 … AC-16，全部有测试守着（`test/flow_test.dart`、`test/journal_card_test.dart`、`test/models_test.dart`）：

| 组 | 覆盖 | 状态 |
|---|---|---|
| 列表（三张种子卡、齿轮 / + 按钮、标题） | AC-1、AC-2 | ✅ |
| 详情页（标题 / 备注 / Back） | AC-3 | ✅ |
| 新增页（字段、保存、空表单提示、只有备注） | AC-4、AC-6、AC-7、AC-7b | ✅ |
| 设置页入口与返回 | AC-5 | ✅ |
| 左滑删除（确认 / 取消） | AC-8、AC-9 | ✅ |
| 详情内编辑回写 | AC-10 | ✅ |
| 加载态 spinner | AC-11 | ✅ |
| 组件与模型契约（不可变、copyWith、required） | AC-12 … AC-16 | ✅ |

## Session 3 · 权限 / 相机相册 / 本地存储 / i18n

`test/session3_test.dart`（AC-S3-1 … AC-S3-12）、`test/photo_store_test.dart`、`test/l10n_test.dart`：

| 要求 | 状态 | 证据 |
|---|---|---|
| 相册 / 相机两个入口 + 空照片位 | ✅ | AC-S3-1 |
| 卡片与详情的照片渲染 / 占位 | ✅ | AC-S3-2 … AC-S3-4 |
| 语言切换并即时生效 | ✅ | AC-S3-5（点「简体中文」界面变「设置」） |
| 清空数据两次确认 | ✅ | AC-S3-6 |
| 语言持久化 | ✅ | AC-S3-7 |
| 存储大小格式化 | ✅ | AC-S3-8 |
| 权限被拒时的引导 | ✅ | AC-S3-9（`photoPermissionDialog` + 打开设置） |
| 重启后数据仍在 | ✅ | AC-S3-10（模拟器实测） |
| 三语键集 / 占位符 / 死键一致 | ✅ | `test/l10n_test.dart` 三条 |
| analyze / test | ✅ | AC-S3-11、AC-S3-12 |

## Session 4 · 图标 / 主题 / 版本 / 插件

### 课件的「Session 4 output」四项

| 输出 | 状态 | 证据 |
|---|---|---|
| App icon 已设置（1024×1024 源图） | ✅ | `assets/icon/icon_1024.png` → `flutter_launcher_icons` → Android 5 档 + iOS 22 文件；解 APK 确认 `mipmap-xxhdpi-v4/ic_launcher.png` 已是新图 |
| Demo 色彩应用到全站 | ✅ | `lib/Utils/app_theme.dart`；截图 `docs/shot-s4-two-pane.png` |
| Settings 显示版本与 build | ✅ | key `appVersion`，`Version 1.1.0 (build 2)`；`build/web/version.json` 同样 |
| iPhone Duo 右侧栏 Back | ⚠️ 代码完成，iOS 真机未验 | `lib/Utils/duo_layout.dart`；AC-S4-06…10 |

### 「Session 4 Challenge」四条

| 要求 | 状态 | 说明 |
|---|---|---|
| 1. 用自己的 logo 生成色板 | ✅ 已生成，未套用 | 从 `assets/icon/icon_1024.png` 提色：`#FFFFFF` 33.9%、`#486BB4` 19.1%、`#444F8E` 10.9%、`#C77A89` 10.2%、`#233872` 10.1%，见 `docs/challenge-s4-palette.png`。**应用用的仍是课件 PART 02 指定的五个 demo 色**（`#025928` / `#F25D27` / `#D9653B` / `#F2B29B` / `#F2F2F2`），因为课件正文要求的就是这套 |
| 2. 把颜色套成 app 主题 | ✅ | `AppTheme.light()`，全仓无硬编码颜色 |
| 3. 设置自己的 1024×1024 图标 | ✅ | 用 `E:\flutter\icon\icon.png`，`remove_alpha_ios: true` |
| 4. 确认图标与主题生效 | ✅ | 图标：解 APK 比对；主题：web 截图 + AC-S4-01/02 |

### 本轮新增的验收标准

AC-S4-01 … AC-S4-16 全绿（见 `PROJECT_SPEC.md` §15.3）。

## 明确没做的

| 项 | 原因 |
|---|---|
| iOS 真机 / 模拟器验证（图标、侧栏 Back、fold 双栏） | 本机是 Windows，不能 `pod install`，也没有 Duo 模拟器 |
| Cursor CLI、SourceTree | 课件是 macOS 口径；Windows 上这两个不是必须，命令行工具替代 |
| 用图标色替换课件色板 | 课件 PART 02 明确规定五个 demo 色；Challenge 的提色结果作为交付物留档，切换与否由主人定 |

## 一句话结论

Session 2 / 3 / 4 的工程要求全部落地并有测试守着（`flutter analyze` 无 issue、`flutter test` 46/46）；
Session 1 的环境项在 Windows 上等价达成（缺 Cursor CLI 与 SourceTree，用 CLI 工具替代）；
唯一没验证的是 iOS 侧的原生插件与图标实机表现，需要在 macOS 上补。
