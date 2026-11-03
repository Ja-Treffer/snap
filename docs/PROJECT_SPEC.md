# EduSnap Pages Demo — 工程文档（v2.4）

> **文档地位**：本文件是生成代码前的唯一契约。代码只实现本文档写明的行为；
> 文档与代码不一致时以本文档为准，并回写修订记录。
>
> **来源**：Itchi Technology Limited《Mobile App Development with Flutter》Session 2
> （`E:\flutter\document\Itchi_Flutter_Session2.pptx.pdf`，正文抽取在
> `E:\flutter\document\session2-text.txt`）。六段 Prompt 全部来自课件，逐字抄录在
> §5。

| 元信息 | 值 |
|---|---|
| 项目 | `demo_pages`（App 名 EduSnap） |
| 版本 / 日期 | v2.4 / 2026-11-03 |
| 状态 | 定稿，代码已按本版生成，analyze / test / build 全绿 |
| 运行形态 | Web（`localhost:8090`）+ Windows 桌面 + Cursor 内 F5 调试 |
| 依赖 | 仅 Flutter SDK，零第三方包 |

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
- Settings 只显示页名 + Back，不做真实设置项（Session 3 起）。
- 不做本地持久化、i18n、相机相册、网络、主题切换（Session 3/4）。
- 卡片不显示时间、不加缩略图（课件只要求 title + note）。
- 不引入任何第三方包，不用命名路由。

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
| 种子色 | `Color(0xFF2E6F95)`，`useMaterial3: true` |
| AppBar | 默认 Material 3 样式；List 左齿轮、右 `+`；Detail 右侧文字 `Edit` |
| 列表内边距 | `EdgeInsets.fromLTRB(12, 8, 12, 12)`，卡片间距 8 |
| 卡片 | `Card` + `ListTile`，title 默认、subtitle 默认 |
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
