# EduSnap Pages Demo — 工程文档（v2.6）

> **文档地位**：本文件是生成代码前的唯一契约。代码只实现本文档写明的行为；
> 文档与代码不一致时以本文档为准，并回写修订记录。
>
> **来源**：Itchi Technology Limited《Mobile App Development with Flutter》Session 2
> （`E:\flutter\document\Itchi_Flutter_Session2.pptx.pdf`，正文抽取在
> `E:\flutter\document\session2-text.txt`）与 Session 3
> （`C:\Users\doubl\Downloads\Itchi_Flutter_Session3.pptx`，抽取在
> `E:\flutter\document\session3-text.txt`）。全部 Prompt 逐字抄录在 §5 与 §13.1。

| 元信息 | 值 |
|---|---|
| 项目 | `demo_pages`（App 名 EduSnap） |
| 版本 / 日期 | v2.5 / 2026-11-10 |
| 状态 | Session 2 + Session 3 已落地，analyze / test / build 全绿 |
| 运行形态 | Android（模拟器 540×1170）+ Web（`localhost:8090`）+ Windows 桌面 |
| 依赖 | `path_provider` `image_picker` `permission_handler` `shared_preferences` `intl` `flutter_localizations` |

---

## 1. 目标与范围

**一句话目标**：四页 + 假数据 + 真导航 + 表单 + 校验 + 左滑删除 + 编辑复用，
全部走 MVC 分层：Model 只装数据，Component 只画卡片，Page 只编排，Controller 只持状态。

### 1.1 范围内

| # | 能力 | 说明 |
|---|---|---|
| 1 | 四个页面 | Home（= List）、Detail、Add、Settings，全部在 `lib/Pages/` 下 |
| 2 | 数据模型 | `JournalEntry`：`title` / `note` / `createdAt` + `copyWith` |
| 3 | 假数据 | 3 条 `sampleEntries()`，`load()` 延迟 300ms 后写入 |
| 4 | 列表 | `ListView.builder` + `JournalCard`，新条目插到最前 |
| 5 | 加载态 | `isLoading` 期间显示 `CircularProgressIndicator` |
| 6 | 真导航 | 点卡片 → Detail（传 entry）；AppBar 右上 `+` → Add；左上齿轮 → Settings |
| 7 | 表单 | Add 页 `Title`（必填）/ `Note`（选填），Save 后 `Navigator.pop(entry)` |
| 8 | 校验 | 标题与备注**都为空** → `Nothing to save` 对话框，不落库；有备注无标题 → 标题存 `Untitled` |
| 9 | 左滑删除 | `Dismissible` 左滑出红底 + 二次确认，确认后从列表移除 |
| 10 | 编辑复用 | Detail 的 `Edit` 复用 `AddPage`，预填原值，保存后 Detail 与 List 同步 |

### 1.2 范围外（明确不做）

- 不建独立 `ListPage`（课件点名禁止：HomePage 就是列表页）。
- 卡片不显示时间、不加缩略图（课件只要求 title + note）。
- 不引入任何第三方包，不用命名路由。

> 以上三条是 Session 2 的口径。Session 3 起：Settings 有了语言与存储两条真实设置，
> 引入了依赖，卡片也加了照片缩略图与创建日期 —— 具体见 §13。

---

## 2. 验收标准

| ID | 操作 | 期望 |
|---|---|---|
| AC-1 | 启动 | AppBar 标题 `List`；三张卡片：`Halley cells` / `Fractions` / `Water cycle` |
| AC-2 | 首页按钮 | 无临时 `Detail`/`Add`/`Settings` 文字按钮；左上齿轮 key `openSettings`，右上 `+` key `openAdd` |
| AC-3 | 点卡片 | 进 Detail；`DetailTitle` 为该条 title，`DetailNote` 为该条 note；`Back` 回列表 |
| AC-4 | 点 `+` | 进 Add（`titleField` / `noteField` / `saveButton` / `AddBack`）；`Back` 回列表 |
| AC-5 | 点齿轮 | 进 Settings（`SettingsBack`）；`Back` 回列表 |
| AC-6 | 填标题保存 | 回列表，新条目在最上方，卡片数 3 → 4 |
| AC-7 | 空表单保存 | 弹 `Nothing to save`（key `emptyEntryDialog`）；`OK` 关闭后仍在 Add 页，列表未变 |
| AC-7b | 只有备注 | 标题留空 + 有备注 → 保存成功，卡片标题为 `Untitled` |
| AC-8 | 左滑 + Delete | 弹确认框（key `deleteConfirm`/`deleteCancel`）；确认后该条消失，卡片数 3 → 2 |
| AC-9 | 左滑 + Cancel | 条目保留，卡片数仍为 3 |
| AC-10 | Detail 内 `Edit` | 预填原值；改名保存后 Detail 显示新名，返回 List 也是新名，数量不变，`createdAt` 不变 |
| AC-11 | 加载期 | 首帧显示 spinner，300ms 后消失并出列表 |
| AC-12 | 组件契约 | `JournalCard` 渲染一个 `Card`，含 title 与 note |
| AC-13 | 组件点击 | `onTap` 被调用时回调触发一次（组件自身不导航） |
| AC-14 | 模型契约 | `title`/`note`/`createdAt` 三字段可读 |
| AC-15 | 构造契约 | 三参数 required named |
| AC-16 | 不可变 | `copyWith` 换 title/note，`createdAt` 保持不变，原对象不变 |
| AC-17 | 静态检查 | `flutter analyze` → `No issues found!` |
| AC-18 | 单元/组件测试 | `flutter test` → 16/16 通过 |
| AC-19 | Web 构建 | `flutter build web --release` 通过 |
| AC-20 | Windows 构建 | `flutter build windows --debug` 通过 |

---

## 3. 信息架构与导航（stack 语义）

```
main() → DemoApp → home: HomePage（= List）
                       ├─ AppBar 左: 齿轮  → SettingsPage  ─'Back'→ pop
                       ├─ AppBar 右: +    → AddPage       ─'Save'→ pop(JournalEntry) → 插到列表最前
                       └─ 卡片 tap        → DetailPage(entry)  ─'Back'→ pop
                                              └─ AppBar 'Edit' → AddPage(entry) ─'Save'→ pop(updated) → Detail 刷新 + onUpdated 回写 List
```

- **push / pop**：`Navigator.push` 压栈、`pop` 出栈，一次 pop 只退一层；`List → Detail → Edit` 三层栈。
- **传参**：构造函数传、`pop` 返回值回传；不引入命名路由或全局状态包。
- **为何 Home 兼任 List**：课件要求 main 只显示 HomePage，两个入口会长出两套状态。

---

## 4. 分层约定

### 4.0 MVC 归属表

| 课件动作 | 归属 | 文件 |
|---|---|---|
| `JournalEntry` 三字段 | **Model** | `lib/Models/JournalEntry.dart` |
| `JournalCard`（Card + ListTile） | **View（Component）** | `lib/Component/JournalCard/JournalCard.dart` |
| 3 条样例 + `isLoading` + `load()` | **Controller** | `lib/Pages/HomePage/HomePageController.dart` |
| `ListView.builder` 遍历、`Dismissible` 包裹 | **View（Page）** | `lib/Pages/HomePage/HomePage.dart` |
| `Navigator.push` / `pop(result)`、`await` 结果 | **Page（路由层）** | Home / Detail / Add |
| 表单校验与 `buildEntry()` | **Controller** | `lib/Pages/Add/AddPageController.dart` |
| Detail 的展示文案 | **Controller** | `lib/Pages/Detail/DetailPageController.dart` |

单向链路：Page 从 Controller 取数据 → 交给 View 画；View 不反向依赖任何东西。

### 4.1 层级规则

| 层 | 允许 | 禁止 | 自检 |
|---|---|---|---|
| Models | 字段、`copyWith` | widget、格式化、校验、导航 | 能在纯 Dart 下跑吗 |
| Component | 布局、样式、透传 `onTap` | 造数据、读写状态、导航 | 换个页面能直接复用吗 |
| Pages | 页面骨架、路由、生命周期、监听 Controller | 在 build 里做业务计算 | 页面里有业务计算吗 |
| Controllers | 状态、校验、转换、通知 | 引用 `BuildContext`、造 widget | controller 里出现 context 了吗 |

### 4.2 文件清单（实际落地，一行一文件）

```
lib/
├─ main.dart                                  main() → DemoApp（主题 + home: HomePage）
├─ Models/JournalEntry.dart                   JournalEntry + copyWith
├─ Component/JournalCard/JournalCard.dart     JournalCard（View，onTap 透传）
└─ Pages/
   ├─ HomePage/HomePage.dart                  List 页：AppBar 两动作 + ListView + Dismissible
   ├─ HomePage/HomePageController.dart        entries / isLoading / load / add / replace / remove
   ├─ Detail/DetailPage.dart                  接收 entry，显示 title/note，Edit 复用 AddPage
   ├─ Detail/DetailPageController.dart        label / title / note 文案
   ├─ Add/AddPage.dart                        Add 与 Edit 共用表单
   ├─ Add/AddPageController.dart              两个 TextEditingController + buildEntry()
   ├─ Settings/SettingsPage.dart              页名 + Back
   └─ Settings/SettingsPageController.dart    label = 'Settings'
test/flow_test.dart                            AC-1..AC-11（11 个）
test/models_test.dart                          AC-14..AC-16（3 个）
test/journal_card_test.dart                    AC-12..AC-13（2 个）
.vscode/launch.json                            Windows / Chrome / web-server / 单测
.vscode/tasks.json                             analyze / test / build web / run windows
docs/PROJECT_SPEC.md                           本文件
docs/shot-list.png                             实机截图（900×700）
```

---

## 5. 课件 Prompt 原文（逐字，代码必须对得上）

**P1 Create pages**
> Modify the main to show HomePage, and update it to be the List page. Do not create a separate List page.
> Create these pages and their controllers under lib/Pages/: Pages/Detail/DetailPage.dart + DetailPageController.dart, Pages/Add/AddPage.dart + AddPageController.dart, Pages/Settings/SettingsPage.dart + SettingsPageController.dart.
> Each page shows a large Text with its name.
> From the List (homepage), temporary buttons go to Detail, Add, and Settings.
> Each page has a Back button that pops.

**P2 Model**
> Create lib/Models/JournalEntry.dart. Fields: String title, String note, DateTime createdAt.
> Add a constructor with required named parameters.
> Do not put any widgets or navigation in this file.

**P3 Dummy data**
> Create a list cell component as a Card under lib/Component/JournalCard/. It should show the title and note of a JournalEntry.
> Then in the homepage (List page), add 3 sample JournalEntry objects and display them in a ListView using this JournalCard component.

**P4 Add form**
> Update AddPage: Title TextFormField (required), Note TextFormField (optional), On Save, create a JournalEntry and Navigator.pop(entry), Do not store the list here.

**P5 Form validation**
> In AddPage: Title TextFormField — required, Note TextFormField — optional.
> On Save: If title is empty, show a dialog/pop-up telling the user the title is missing; If valid, create a JournalEntry and Navigator.pop(entry).

**P6 List holds data**
> In the HomePage (List): Hold a List<JournalEntry> in the controller; Show them in a ListView using the JournalCard component.
> When the Add button opens AddPage: Wait for the result with await Navigator.push(...); If a JournalEntry is returned, insert it at the top of the list.

**P7 Detail receives data**
> Update DetailPage: Receive a JournalEntry from List; Show title and note of that entry; From List, tap a cell to open Detail and pass the entry.

**P8 Swipe delete**
> In the HomePage, wrap each JournalCard with Dismissible. Swipe left shows a delete background; On confirm, remove the JournalEntry from the list; Update the UI.

**P9 Real navigation（取代 P1 的临时按钮）**
> Update navigation and UI: Tap a card on List → open DetailPage and pass the JournalEntry; Top-right button in AppBar → open AddPage; DetailPage shows title and note of the passed entry; Remove the temporary buttons; Move Setting button to top left in AppBar.

**Challenge（Session 2 挑战，已实现）**
> Reuse the Add page as an Edit page. From Detail, add an Edit button that opens AddPage and passes the existing JournalEntry; AddPage reads the passed entry and fills the form (title, note); On Save, update the entry and pop the result; List and Detail should show the updated data.

---

## 6. 模型与组件契约

### 6.1 `JournalEntry`

```dart
class JournalEntry {
  const JournalEntry({
    required this.title,
    required this.note,
    required this.createdAt,
  });

  final String title;
  final String note;
  final DateTime createdAt;

  JournalEntry copyWith({String? title, String? note}) => JournalEntry(
        title: title ?? this.title,
        note: note ?? this.note,
        createdAt: createdAt,
      );
}
```

- 零 import（连 `material.dart` 都不引）、零 widget、零导航。
- **不设 `id`**：课件模型只有三个字段；列表用对象身份（`identical` / `ObjectKey`）区分条目，够用且不污染模型。
- `copyWith` 只换 title/note，`createdAt` 永远沿用原值。

### 6.2 `JournalCard`

```dart
class JournalCard extends StatelessWidget {
  const JournalCard({super.key, required this.entry, this.onTap});

  final JournalEntry entry;
  final VoidCallback? onTap;
  // Card > ListTile(onTap, title: Text(entry.title), subtitle: Text(entry.note))
}
```

- 只画不存：不持有状态、不 `Navigator.push`；点击行为由页面通过 `onTap` 注入。

---

## 7. 页面契约

### 7.1 HomePage（= List）

| 项 | 内容 |
|---|---|
| 职责 | 展示条目、加载态、空态；承载真导航与左滑删除 |
| 输入 | 无 |
| 输出 | 无（内部把 Add 的返回值插进 controller） |
| 状态 | 自建 `HomePageController`；`initState` 调 `load()`；`ListenableBuilder` 订阅；`dispose` 释放 |
| 结构 | `AppBar(title:'List', leading: 齿轮, actions:[+])` + `ListView.builder` → `Padding` → `Dismissible` → `JournalCard(onTap)` |
| Key | `openSettings` / `openAdd` / `emptyList` / `deleteConfirm` / `deleteCancel` |

### 7.2 AddPage（Add 与 Edit 共用）

| 项 | 内容 |
|---|---|
| 职责 | 收集 title/note，校验后把 `JournalEntry` 回传给调用方 |
| 输入 | `JournalEntry? entry`（非空即 Edit 模式，预填） |
| 输出 | `Navigator.pop(JournalEntry)`；取消则 `pop()` 不带值 |
| 状态 | `AddPageController` 持有两个 `TextEditingController`，`dispose` 释放 |
| 结构 | `AppBar(title: 'Add'/'Edit')` + `ListView[titleField, noteField, saveButton, AddBack]` |
| Key | `titleField` / `noteField` / `saveButton` / `AddBack` / `emptyEntryDialog` / `emptyEntryOk` |

### 7.3 DetailPage

| 项 | 内容 |
|---|---|
| 职责 | 显示收到的条目；提供 Edit（复用 AddPage）与 Back |
| 输入 | `JournalEntry entry` + `ValueChanged<JournalEntry>? onUpdated` |
| 输出 | `pop()`；编辑结果通过 `onUpdated` 回写 List |
| 状态 | `_entry` 本地持有，编辑后 `setState` |
| 结构 | `AppBar(title:'Detail', actions:[Edit])` + `ListView[DetailTitle, DetailNote, DetailBack]` |
| Key | `DetailTitle` / `DetailNote` / `DetailEdit` / `DetailBack` |

### 7.4 SettingsPage

显示 `Settings` 大号文字 + `Back`（key `SettingsBack`）；真实设置项推迟到 Session 3。

---

## 8. 视觉规范

| 项 | 值 |
|---|---|
| 调色板 | Session 4 起：Primary `#025928`、Secondary `#F25D27`、Accent `#D9653B`、Surface `#F2B29B`、Background `#F2F2F2`；全部定义在 `lib/Utils/app_theme.dart` |
| 主题入口 | `AppTheme.light()`，`useMaterial3: true`；`accent` 落到 M3 的 `tertiary`，`surface` 用于 Card 与 `surfaceContainerHighest`，`background` 同时做 `scaffoldBackgroundColor` |
| 颜色纪律 | 页面/组件不写 `Color(0x…)`，只读 `Theme.of(context).colorScheme`（唯一例外就是 `app_theme.dart` 本身） |
| AppBar | 绿底白字（`appBarTheme`）；List 左齿轮、右 `+`；Detail 右侧文字 `Edit` |
| 列表内边距 | `EdgeInsets.fromLTRB(12, 8, 12, 12)`，卡片间距 8 |
| 双栏 | 短边 ≥ 600 且（hinge fully open 或长边 ≥ 640）时两列独立滚动 |
| 卡片 | `Card` + `ListTile`，title 默认、subtitle 默认，卡片底色取 surface |
| 删除背景 | `colorScheme.errorContainer` 圆角 12 + `onErrorContainer` 的 `delete_outline` |
| 表单 | `OutlineInputBorder`，Title 单选行 `next`，Note `minLines 3 / maxLines 6` |
| 按钮 | 主操作 `FilledButton`，次要 `TextButton` |
| 文案 | 全英文，与课件一致 |

---

## 9. 边界与异常

| 场景 | 处理 |
|---|---|
| 加载未完成 | 列表位 spinner，不显示空列表 |
| 列表为空 | 居中 `No entries yet`（key `emptyList`） |
| 标题与备注都为空/全空格 | 弹 `Nothing to save`，不 pop、不入列表 |
| 标题空但有备注 | 不拦截，标题落 `Untitled`（常量 `AddPageController.untitled`，i18n 阶段转 ARB） |
| Note 为空 | 允许保存，Detail 显示 `No note` |
| 删除 | 必须二次确认；取消则条目回到原位 |
| 编辑 | 用对象身份替换原元素，`createdAt` 不变；替换失败（已被删）静默返回 |
| 连续 push | 一层 pop 退一层，符合 `List → Detail → Edit` 栈语义 |
| 窄窗口 | AppBar 动作不参与布局宽度；卡片随宽度伸缩 |

---

## 10. 测试计划

| 用例 | 覆盖 | 断言 |
|---|---|---|
| flow AC-1 | 首页 | 标题 `List`；`JournalCard` 3 个；三条标题各 1 次 |
| flow AC-2 | 按钮布局 | 三个旧 key 不存在；`openAdd`/`openSettings` 存在 |
| flow AC-3 | 卡片 → Detail | `DetailTitle` 文本 == `Fractions`，`DetailNote` 等于原文 |
| flow AC-4 | `+` → Add | `titleField` 出现；`AddBack` 返回后消失 |
| flow AC-5 | 齿轮 → Settings | `SettingsBack` 往返 |
| flow AC-6 | 新增 | 输入标题/备注保存后卡片 4 个，新条目 y 坐标小于旧首条 |
| flow AC-7 | 校验 | 空表单 → 对话框；关闭后仍在 Add 页 |
| flow AC-7b | 兜底标题 | 只填备注 → 列表出现 `Untitled` |
| flow AC-8 | 左滑删除 | 拖 -600 出确认框；确认后卡片 2 个 |
| flow AC-9 | 左滑取消 | 取消后卡片仍 3 个 |
| flow AC-10 | 编辑复用 | Detail 内改名 → Detail 与 List 同步，数量不变 |
| flow AC-11 | 加载态 | 首帧 spinner，400ms 后消失 |
| models AC-14..16 | 模型 | 字段、required named、copyWith 保留 createdAt |
| card AC-12..13 | 组件 | Card + 文本；`onTap` 触发一次 |

`_pumpApp`：`pumpWidget` → `pump(400ms)` → `pumpAndSettle()`，用来越过 300ms 假加载。

---

## 11. 技术债防线

- [x] 零第三方依赖；不用命名路由。
- [x] Model 零 import；Component 零导航；Controller 零 `BuildContext`。
- [x] 所有可变状态走 controller 方法，页面不直接改列表（`entries` 返回 `unmodifiable`）。
- [x] 每个可点/可断言元素有 `Key`。
- [x] `file_names` 豁免集中在 `analysis_options.yaml`。
- [x] `Dismissible` 的 key 用 `ObjectKey(entry)`，不用 `index`（删中间项不会错位）。
- [x] 测试 ↔ 验收标准一一对应。

### 技术债台账

| 债务 | 原因 | 偿还时机 |
|---|---|---|
| 无持久化 | 本段全是内存数据 | Session 3（本地存储） |
| Settings 无内容 | 课件本段只要求页名 | Session 3 起 |
| `createdAt` 不显示 | 课件只要求 title + note | 需要时加进 subtitle |
| 无撤销删除 | 课件只要求"确认后删除" | 可选打磨（Session 4） |
| 文案硬编码英文 | i18n 属后续 Session | Session 4 抽 `strings.dart` |

---

## 12. 修订记录

| 版本 | 日期 | 变更 |
|---|---|---|
| v1.0–v1.1 | 2026-11-03 | 首版与结构重组（过度设计，四页带真实内容） |
| v2.0 | 2026-11-03 | 按 P1 重写：Home 兼任 List、PascalCase、大号页名 + Back |
| v2.1 | 2026-11-03 | 按「Running app」截图收窄：四页只留页名 + 文字按钮 |
| v2.2 | 2026-11-03 | 新增 `JournalEntry`（P2） |
| v2.3 | 2026-11-03 | 新增 `JournalCard` + 3 条假数据 + 加载态（P3），Home 改 StatefulWidget |
| v2.4 | 2026-11-03 | 落地 Session 2 后半全部 Prompt：P4/P5 Add 表单与校验、P6 列表持数据 + `await push` 插最前、P7 Detail 收数据、P8 `Dismissible` 左滑删除、P9 真导航（临时按钮删除、齿轮移到 AppBar 左上）；Challenge 编辑复用已实现（`AddPage(entry:)` + `copyWith`）；Home 目录按课件表格改为 `Pages/HomePage/`；AC 重编为 1–20，测试 16 个全过 |
| v2.5 | 2026-11-10 | 并入 Session 3（权限 / 相机相册 / 本地存储 / i18n / Challenge 存储格式化）：新增 §13，AC-S3-1…AC-S3-12，新增 `PhotoStore` / `AppSettings` / `AppScope` / `l10n`；依赖从「零第三方」改为 path_provider + image_picker + permission_handler + shared_preferences + intl + flutter_localizations；测试 27 个全过 |

---

## 13. Session 3 · 权限、照片、存储、语言

> 来源：`Itchi_Flutter_Session3.pptx`（36 页，2026-11-10 抽取到
> `E:\flutter\document\session3-text.txt`）。本节四条 Prompt 为课件原文。

### 13.1 课件 Prompt（逐字）

**P1（p12，权限与依赖）**

```
Add image_picker and permission_handler.
Then configure permissions for both platforms:
iOS — ios/Runner/Info.plist: NSCameraUsageDescription, NSPhotoLibraryUsageDescription
Android — AndroidManifest.xml: CAMERA, READ_MEDIA_IMAGES (or READ_EXTERNAL_STORAGE)
After AI adds them, run cmd "flutter pub get" and check for errors.
```

**P2（p15，Add 页选照片）**

```
On AddPage, add a button to pick a photo.
• Use image_picker to open gallery or camera
• Request permission first with permission_handler
• If granted, show the selected image on the form
• If denied, show a dialog that explains the permission is needed and has a button to open the app settings
• Store the image path on the JournalEntry
```

**P3（p17，卡片与详情显示照片）**

```
Update JournalCard and DetailPage:
• If the JournalEntry has a photo path, show the image
• If no photo, show a placeholder
• Keep the layout clean
```

**P4（p20，本地存储）**

```
Add shared_preferences (or a simple JSON file).
In the HomePage controller:
• On initState, load the list of JournalEntry from local storage
• When the list changes (add / delete / edit), save it
• Quit the app and reopen — the entries should still be there
```

**P5（p24，i18n 骨架）**

```
Add flutter_localizations and intl support.
• Update pubspec.yaml
• Run flutter pub get
• Enable localization in MaterialApp
• Also add support of Traditional Chinese
```

**P6（p26，ARB 文案）**

```
Create ARB / string files for English and Traditional Chinese.
• Add the string keys for all UI
• Provide English and Chinese translations
• Use the generated localizations in the UI
```

**P7（p28，语言开关）**

```
On Settings page, add a language toggle.
• Switch between English and Chinese
• Save the choice in local storage
• Load it on next launch
```

**P8（p31，日期占位符）**

```
Update the date display for journal entries to use localization with a placeholder.
• English: "Created on {date}"
• Chinese: "{date} 建立"
• Use a placeholder for the date so the word order can differ between languages.
• Show the formatted date on the Detail page (and List card if space allows).
```

**Challenge（p34，存储格式化）**

```
Add a format function on the Settings page.
1. Show the size of local storage
2. Use a placeholder (Chinese 已使用 0 KB / English 0 KB used)
3. Add Format / Clear buttons with a double confirmation
4. Clear all entries and their photos
5. After clearing, the size shows 0 KB
```

### 13.2 新增/改动的文件

| 文件 | 职责 |
|---|---|
| `lib/Utils/photo_store.dart` | 照片落盘：`import()` 复制进 `documents/photos/`，`pathOf()` 同步取路径，`clearAll()` / `usedBytes()` |
| `lib/Utils/app_settings.dart` | 语言偏好（`ChangeNotifier` + `shared_preferences`），`system` 走系统语言 |
| `lib/Utils/app_scope.dart` | `InheritedWidget`，向下传 `settings` / `photos` / `journal` |
| `lib/Utils/formatters.dart` | `formatEntryDate(value, localeName)`、`formatStorageSize(bytes)` |
| `lib/l10n/app_en.arb` `app_zh.arb` `app_zh_Hant.arb` | 全量文案 + 占位符元数据 |
| `test/l10n_test.dart` | i18n 三条红线：键集一致 / 占位符一致 / 无死键 |
| `l10n.yaml` | `arb-dir: lib/l10n`、`output-class: AppLocalizations`、`nullable-getter: false` |
| `lib/Utils/journal_store.dart` | 追加 `sizeInBytes()` / `deleteFile()` |
| `lib/Pages/Add/AddPage.dart` | 照片区（相机/相册/移除）+ 权限拒绝对话框 |
| `lib/Pages/Settings/SettingsPage.dart` | 语言四选一、存储用量、双重确认清空 |

### 13.3 验收标准（Session 3）

| ID | 操作 | 期望 |
|---|---|---|
| AC-S3-1 | 打开 Add | 有 `pickFromGallery` / `pickFromCamera`，照片位显示 `addPhotoPlaceholder` |
| AC-S3-2 | 列表卡片 | 无照片时每张卡有 `cardPhotoPlaceholder`，无 `cardPhoto` |
| AC-S3-3 | 有照片的卡 | 渲染 `Image.file`（key `cardPhoto`） |
| AC-S3-4 | Detail | 有 `DetailCreatedOn`，文案以 `Created on ` 开头且含年份；无照片显示 `detailPhotoPlaceholder` |
| AC-S3-5 | Settings 语言 | 点 `languageChinese` 后界面变 `设置`，`settings.localeCode == 'zh'` |
| AC-S3-6 | 清空 | 两次确认（先 Cancel 不生效）；确认后 `0 KB used`，回列表为 `emptyList` |
| AC-S3-7 | 语言持久化 | 设 `zh_Hant` 后重建 `AppSettings` 仍为 `zh_Hant`，`toLanguageTag() == 'zh-Hant'` |
| AC-S3-8 | 存储文案 | `formatStorageSize`：`0`→`0 KB`、`651`→`0 KB`、`2048`→`2 KB`、3MB→`3.0 MB` |
| AC-S3-9 | 权限拒绝 | 未授予且用户拒授 → `photoPermissionDialog`，含 `permissionOpenSettings` |
| AC-S3-10 | 重启 | 强杀进程重开，条目与语言都还在（模拟器实测） |
| AC-S3-11 | 静态检查 | `flutter analyze` → `No issues found!` |
| AC-S3-12 | 测试 | `flutter test` → 27/27 通过 |

### 13.4 边界与异常

| 情况 | 行为 |
|---|---|
| 相册里选了超大图 | `pickImage(maxWidth: 1600, imageQuality: 85)` 先压缩再落盘 |
| 用户删掉条目 | 连带删除 `photos/` 下对应文件 |
| 编辑时换照片 | 旧文件删除，新文件入库 |
| `journal.json` 损坏 | 改名 `journal.json.bak-<ms>`，以空列表启动（不覆盖用户数据） |
| 清空后立刻看大小 | `formatStorageSize` 向下取整，`651` 字节也显示 `0 KB` |
| 清空后条数 | `SettingsPage.entryCount` 传 **getter** `int Function()`，否则清空后副标题还显示旧值（实测抓到的 bug） |
| iOS 缺 `NSCameraUsageDescription` | 一开相机就被系统杀掉，所以两条描述必须写在 `Info.plist` |

### 13.5 技术债台账（Session 3 追加）

| 债务 | 原因 | 偿还时机 |
|---|---|---|
| 相册用 `READ_MEDIA_IMAGES` 声明但实际走 Photo Picker | 课件要求声明；现代 Android 不需要该权限 | Session 4 复核 |
| `permission_handler` 逼着 `compileSdk = 37` | 13.x 的 AAR 元数据要求，Flutter 默认还是 36 | 等 Flutter 默认值跟上后改回 |
| 照片只存文件名不存缩略图 | 列表直接 `Image.file`，大图会吃内存 | 需要时加缓存缩略图 |
| 语言只做 en / zh / zh_Hant | 课件只要这三种 | Session 4 |

## 14. 技术债偿还记录（2026-11-10）

本轮清理的债务与对应验收：

| 债务 | 处理 | 验收 |
|---|---|---|
| 选图后放弃表单，照片文件残留在 `photos/` | `PhotoStore.deleteUnreferenced` + `HomePageController.purgeOrphanPhotos`；启动、取消返回、点移除三处触发 | AC-S3-13 / AC-S3-14 |
| 点「移除照片」只清 UI 不删文件 | `AddPage._removePhoto` 先删文件再 `setState` | AC-S3-15 |
| 删除在 Windows 上偶发失败（句柄未释放） | `PhotoStore.delete` 失败重试一次，仍失败交给下次启动回收 | 手工验证 |
| 卡片缩略图按原图解码吃内存 | `Image.file(cacheWidth: (56 * 3).round())` | 目测 + 无回归 |
| `AddPage.imagePicker` 注入被字段覆盖，测试驱动不到真实路径 | 改 getter `_picker => widget.imagePicker ?? _defaultPicker` | AC-S3-14 / AC-S3-15 |
| 权限在 widget 测试里没有平台实现 | 用 `PermissionHandlerPlatform` 假实现 + dev 依赖补齐 | 新增用例可跑 |

**复核后仍保留的债务**：`compileSdk = 37`（依赖要求）、`READ_MEDIA_IMAGES` 声明（课件要求）、照片只有原图无缩略图缓存、语言仅三语。保留理由与偿还时机见 §13.5。

**注意**：`docs/rag/07-pitfalls.md` 第 1、2、12 条即本轮结论，改这些行为时三处（代码、spec、rag）要一起改。

**本轮新增的验收标准**（写入 `test/photo_store_test.dart`）：

- `AC-S3-13`：`deleteUnreferenced(keep)` 只删白名单外的照片，`usedBytes` 随之下降。
- `AC-S3-14`：`purgeOrphanPhotos()` 会把「选了图但没保存」留下的副本删掉，且不动被条目引用的照片。
- `AC-S3-15`：点「移除照片」后占位符回来，磁盘上那张文件立即消失。

**本轮新增的验收标准（i18n）**：

- `AC-S3-16`：`test/l10n_test.dart` 三条全绿——三语键集一致、占位符一致、模板无死键。

---

## 15. Session 4 · 图标、主题、版本、原生插件

课件四段：PART 01 app icon、PART 02 app theme、PART 03 app version、PART 04 native plugin。
本轮只做这四件事 + Checkpoint，其余一律进台账。

### 15.1 落地内容

| 段 | 要求（课件原意） | 本工程的做法 |
|---|---|---|
| 01 Icon | 一张 1024×1024 PNG 生成 iOS + Android 全部尺寸 | `assets/icon/icon_1024.png`（源图 RGBA）；pubspec 加 `flutter_launcher_icons`，`remove_alpha_ios: true`；`dart run flutter_launcher_icons` 产出 Android 5 档 mipmap + iOS 22 个 appiconset 文件 |
| 02 Theme | Primary `#025928` / Secondary `#F25D27` / Accent `#D9653B` / Surface `#F2B29B` / Background `#F2F2F2`，套在 `MaterialApp` 上，widget 里不许硬编码颜色 | 新建 `lib/Utils/app_theme.dart`；`AppTheme.light()` 用 `ColorScheme.fromSeed(primary).copyWith(...)`；`main.dart` 改用它；grep `Color(0x` 全仓只剩这个文件 |
| 03 Version | Settings 显示 version + build；改 pubspec 重启生效 | 加 `package_info_plus`；`Models/AppVersion.dart` 纯数据；`SettingsPageController.refreshVersion()` 注入可测；Settings 新增 About 段 + key `appVersion`；pubspec `1.1.0+2` |
| 04 Plugin | Git 依赖 `itchi_flutter_duo_layout`，侧栏 Back，rail 激活时隐藏 Flutter 返回键，监听 fold，完全打开走双栏 | `lib/Utils/duo_layout.dart` 封装 `DuoLayoutController` + `DuoBridge` 接缝；`DemoApp` 传全局 `navigatorKey`；Home/Detail/Add/Settings 的 AppBar 按 `railActive` 关掉自带 leading；Home 在 `wantsTwoPanes` 时双列 |

### 15.2 新增 / 改动的文件

| 文件 | 动作 |
|---|---|
| `assets/icon/icon_1024.png` | 新增（源图副本） |
| `android/app/src/main/res/mipmap-*/ic_launcher.png`、`ios/Runner/Assets.xcassets/AppIcon.appiconset/*` | 生成（勿手改） |
| `lib/Utils/app_theme.dart` | 新增 |
| `lib/Utils/duo_layout.dart` | 新增 |
| `lib/Models/AppVersion.dart` | 新增 |
| `lib/Utils/app_scope.dart` | 改：加可选 `duo` |
| `lib/main.dart` | 改：`AppTheme.light()`、`navigatorKey`、`duo` 注入与 start/dispose、外观合并重建 |
| `lib/Pages/Settings/SettingsPage.dart` | 改：About 段 + 版本行 + 可注入 controller + 按 `railActive` 关返回键 |
| `lib/Pages/Settings/SettingsPageController.dart` | 改：`version` / `refreshVersion` / `loadVersion` 注入 |
| `lib/Pages/HomePage/HomePage.dart` | 改：双栏布局 + `railActive` |
| `lib/Pages/Detail/DetailPage.dart`、`lib/Pages/Add/AddPage.dart` | 改：按 `railActive` 关返回键 |
| `lib/l10n/app_en.arb` / `app_zh.arb` / `app_zh_Hant.arb` | 改：`settings_about`、`settings_version{version,build}` |
| `test/session4_test.dart` | 新增（13 例） |
| `test/flow_test.dart` | 改：AC-5 先滚到 `SettingsBack`（About 段把它推到折叠线以下） |

### 15.2b 追加：背景图 + 透明度（课后要求）

课件没有这一段，是课后加的功能需求（「导入图片和调整透明度」）。

| 项 | 做法 |
|---|---|
| 存储 | `AppSettings.backgroundImage`（**文件名**，落在 `photos/`）+ `backgroundOpacity`（0.05–1.0，默认 0.35）；键 `app.backgroundImage` / `app.backgroundOpacity` |
| 导入 | Settings 首选图 → `PhotoStore.import` 复制进 `photos/` → 存文件名；换图时删掉上一张，不堆文件 |
| 渲染 | `lib/Component/BackgroundLayer/BackgroundLayer.dart`：`MaterialApp.builder` 里垫 `Image.file(fit: cover)`，透明度用 `AlwaysStoppedAnimation` |
| 透明脚手架 | 有背景图时 `AppTheme.light(transparentScaffold: true)`，让图从卡片缝隙透出；无图时仍是 `#F2F2F2` |
| 孤儿清理 | `HomePageController.purgeOrphanPhotos` 的 `keep` 集合加入 `settings.backgroundImage`，否则启动扫描会把它删掉 |
| 失败处理 | 相册打不开 / 复制失败 → SnackBar `settings_background_failed`；文件读不到 → `errorBuilder` 给空片，不崩 |
| web | `dart:io` 在 web 不可用，`BackgroundLayer` 用 `kIsWeb` 直接跳过（只显示纯色底） |

### 15.3 验收标准（Session 4）

| ID | 操作 | 期望 |
|---|---|---|
| AC-S4-01 | 读 `AppTheme.light().colorScheme` | primary/secondary/tertiary/surface 与 §8 五个色值一致 |
| AC-S4-02 | 读主题 | AppBar 绿底白字，scaffold 背景 `#F2F2F2` |
| AC-S4-03 | 注入 `loadVersion` 后 `refreshVersion()` | `version` 为 `1.1.0` / `2` |
| AC-S4-04 | `loadVersion` 抛异常 | 落到 `AppVersion.unknown`，不抛 |
| AC-S4-05 | 打开 Settings 滚到底 | 出现 `Version 1.1.0 (build 2)`（key `appVersion`） |
| AC-S4-06 | 非 iOS 启动 | `railActive == false`，仍尝试调用一次 setVisible，stop 时关掉 |
| AC-S4-07 | 通道缺失 | 同上，不抛 |
| AC-S4-08 | 平台答 `available` | `railActive == true`，原生 Back 事件转发到回调 |
| AC-S4-09 | fold 流推 `fullyOpen` | 900×700 判为双栏；400×800 仍单栏 |
| AC-S4-10 | 无 hinge 的大窗 | 900×700 双栏；500×900 单栏 |
| AC-S4-11 | 设置背景图与透明度后重启 | `AppSettings` 读回同一个文件名与 `0.6` |
| AC-S4-12 | 透明度越界 | 钳到 `0.05` / `1.0`，不抛 |
| AC-S4-13 | 未选背景图 | 页面不渲染额外图片层，仍是纯色底 |
| AC-S4-14 | 静态检查 | `flutter analyze` → `No issues found!` |
| AC-S4-15 | 测试 | `flutter test` → 46/46 |
| AC-S4-16 | 构建 | `flutter build web --release` + `flutter build apk --debug` 通过；APK 内 `mipmap-xxhdpi-v4/ic_launcher.png` 为新课件图标 |

### 15.4 边界与异常

| 场景 | 处理 |
|---|---|
| 平台没有插件（Android / Web / Windows / 测试） | `setSideBackVisible` 返回 `unsupportedPlatform`，`railActive` 保持 false，页面自带返回键照常 |
| MethodChannel 抛错 | `catch` 成 `railActive = false`，等同非 Duo 设备 |
| fold 通道 onError | 吞掉，`fold` 保持上一次值 |
| `PackageInfo` 读不到（测试 / 某些 web 宿主） | 版本显示 `—`，不崩 |
| 窗口很宽但没有 hinge | 按尺寸兜底：短边 ≥ 600 且长边 ≥ 640 才双栏 |
| 双列时条目很少 | 右列空列表，不报错 |
| 背景图文件被删 / 损坏 | `errorBuilder` 给空片，页面回到纯色底，不崩 |
| 背景图与照片同目录 | 孤儿清理的白名单里包含它，不会被当垃圾扫掉 |
| web 上选背景图 | 可以设置，但 `BackgroundLayer` 跳过 `dart:io`，画面仍是纯色 |

### 15.5 技术债台账（Session 4 追加）

| 债务 | 原因 | 偿还时机 |
|---|---|---|
| iOS 侧栏 / fold 真机未验证 | 本机是 Windows，无法 `pod install` 也不能跑模拟器 | 有 Mac 或真机时按 §15.6 复核 |
| Android adaptive icon 未配置 | 源图主体满幅，做前景层会被裁切 | 拿到带留白的品牌图后加 `adaptive_icon_*` |
| Windows 构建未验证 | 插件工程需要符号链接支持（见 rag 07） | 开启开发者模式并重新登录后补 |
| 双栏只是两列列表，没有主从布局 | 课件只要求「fully open 用全屏布局」 | 真正做平板/折叠屏时再设计 |

### 15.6 留给 iOS 的复核步骤（未验证）

1. `cd ios && pod install`（Windows 上跑不了，只能在 macOS 执行）。
2. iPhone Duo 模拟器 `flutter run -d "iPhone Duo"`。
3. 检查：详情页没有两个返回键；侧栏 Back 能 pop；折叠到 fully open 时列表变两列。
4. 若 rail 显示但点不动，先看 `ItchiRailStatus` 是否 `viewUnavailable`（首帧未就绪，重试即可）。

