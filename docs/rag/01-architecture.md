# 01 · 架构与分层

一句话：**四层目录 + 每页一对 Page/Controller**，依赖只能从上往下走。

## 目录

```
lib/
  Models/           纯数据类，零 import（除了 dart:core 自带的）
  Component/        可复用 UI，一个组件一个文件夹
  Pages/            一个页面一个文件夹，Page 与 PageController 同放
  Utils/            跨页面共享的非 UI 逻辑（存储、设置、格式化、Scope）
  l10n/             ARB 原文 + gen-l10n 生成的代码
```

## 每层能做什么

| 层 | 允许 | 禁止 |
| --- | --- | --- |
| `Models/` | 字段、`copyWith`、`toJson` / `fromJson`、纯计算 getter | 任何 `flutter/*` import、文件 IO、导航 |
| `Component/` | 只画 UI，接收已算好的值与回调 | 自己读文件、自己 push 路由、自己发请求 |
| `Pages/*/XxxPage.dart` | 组装 widget、`Navigator`、弹窗、调 Controller | 直接 `File(...)` 读写、直接 `SharedPreferences` |
| `Pages/*/XxxController.dart` | 状态、业务判断、编排 Utils | 持有 `BuildContext`（唯一例外是构造时注入的回调） |
| `Utils/` | 文件、偏好、格式化、依赖注入容器 | 页面 UI、`Navigator` |

## 依赖注入缝：`AppScope`

`lib/Utils/app_scope.dart` 把三个服务挂在树上：`settings`（AppSettings）、`photos`（PhotoStore）、`journal`（JournalStore）。

- 页面里要服务：`AppScope.of(context).photos`。
- 这个缝的唯一目的就是**让测试换成内存实现**（见 02）。

## 谁可以 `notifyListeners()`

只有 Controller，而且只在**值真的变了**之后：

```dart
// lib/Utils/app_settings.dart
Future<void> setLocaleCode(String code) async {
  if (code == _localeCode) return;   // 先比较
  _localeCode = code;
  notifyListeners();                 // 再通知
  ...
}
```

## 页面三态

List 页只有三种合法画面：`loading` → `spinner`、`isEmpty` → 空态文案、否则 → 列表。写新页面时照抄这个骨架，不要发明第四种。

## 命名

- 目录与文件名跟课件一致用 PascalCase：`Pages/Add/AddPage.dart`、`Pages/Add/AddPageController.dart`。
- 因此 `analysis_options.yaml` 里对 `file_names` 集中豁免了一条 lint —— 不在每个文件堆 `// ignore`。
- 其余 lint 全开，`flutter analyze` 必须干净才算完工。

## 最后核对

2026-11-10，对照 `lib/` 全量核对。
