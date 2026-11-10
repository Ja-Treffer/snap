# 03 · 页面与导航

一句话：**四个页面，List 是根；只在需要回传结果时用 `await push<T>`，其余 push 完就忘。**

## 页面地图

```
HomePage（List，根页，无输入）
├─ +  ──────────────► AddPage（无输入 / entry=null）  ──pop(JournalEntry?)─► 插入列表顶部
├─ 列表项 ──────────► DetailPage(entry, onUpdated) ──pop(JournalEntry?)─► 回写列表
│                        └─ Edit ─► AddPage(entry) ──pop(JournalEntry?)─► 刷新本页 + onUpdated
└─ 齿轮 ────────────► SettingsPage(entryCount, onClearAll)
```

## 导航约定

| 场景 | 写法 | 理由 |
| --- | --- | --- |
| 打开子页不关心返回值 | `Navigator.push<void>(MaterialPageRoute<void>(...))` | 不写 `await`，页面里没有“返回时刷新”的负担 |
| 子页要交回数据 | `final X? result = await Navigator.push<X>(...)`，回来判空 | 取消 → `null`，不要用哨兵对象 |
| 返回 | `Navigator.pop()` / `pop(value)` | AppBar 的返回键由 Flutter 自动提供，另加一个页面内 Back 按钮是课件的教学要求 |
| 命名路由 | 不用 | 页面参数是必填对象，命名路由只能传 `Object?`，类型安全全丢 |

## 各页契约

### HomePage（`lib/Pages/HomePage/HomePage.dart`）

- 输入：`controller`（可注入，测试用）。
- 状态：`isLoading` / `isEmpty` / 有数据。
- AppBar：左 `IconButton(Icons.settings_outlined)` key `openSettings`；右 `IconButton(Icons.add)` key `openAdd`；标题用 ARB `homepage_title`。
- 列表项：`Dismissible`（`key: ObjectKey(entry)`，`endToStart`）包 `JournalCard`，`confirmDismiss` 弹确认框。
- 空态：`Text` key `emptyList`。

### AddPage（`lib/Pages/Add/AddPage.dart`）

- 输入：`entry`（非空即编辑模式）、`imagePicker`（仅测试注入）。
- 字段：`titleField`、`noteField`；照片区 `addPhotoPlaceholder` / `addPhotoPreview` / `pickFromGallery` / `pickFromCamera` / `removePhoto`。
- 校验：全空（标题、备注、照片都没有）才拦，弹 `emptyEntryDialog` + `emptyEntryOk`。
- 保存：`pop(buildEntry(untitledLabel: l10n.entry_untitled))`；空标题存成 ARB 里的 `Untitled`。
- 编辑：手工构造新对象并**沿用 `createdAt`**；不要用 `copyWith` 拼装，否则删照片不会生效（`copyWith` 的 `null` 表示“不改”）。

### DetailPage（`lib/Pages/Detail/DetailPage.dart`）

- 输入：`entry`、`onUpdated`。
- 展示：`AspectRatio(4/3)` 图（`detailPhoto`）或占位（`detailPhotoPlaceholder`）、`DetailTitle`、`DetailCreatedOn`、`DetailNote`、`DetailBack`。
- 编辑：AppBar `TextButton` key `DetailEdit` → `await push<JournalEntry>(AddPage(entry: _entry))` → 非空则 `setState` 更新本地副本并 `widget.onUpdated?.call(updated)`。

### SettingsPage（`lib/Pages/Settings/SettingsPage.dart`）

- 输入：`entryCount`（**`int Function()`**，不是 `int`）、`onClearAll`。
- 语言四行：`languageSystem` / `languageEnglish` / `languageChinese` / `languageChineseTraditional`，选中态用 `Icons.radio_button_checked`（`RadioListTile` 的 `groupValue` 在新版已弃用）。
- 存储行 key `storageUsed`，副标题显示条数——所以 `entryCount` 必须是函数，否则清空后还显示旧数字。
- 清空：`clearAllButton` → `clearConfirmDialog`（`clearCancel` / `clearConfirm`）→ `clearConfirmAgainDialog`（`clearAgainCancel` / `clearAgainConfirm`）→ 执行 + SnackBar `settings_cleared`。

## 子页改数据，必须有人回写

`DetailPage` 改了 entry，列表不会自己知道。链条是：
`DetailPage` 改本地 → `onUpdated(updated)` → `HomePageController.replaceEntry(old, updated)`（用 `identical` 找位置）→ `notifyListeners()` → 列表重画 + 落盘。

漏掉任何一环，表现都是“详情改了，回列表还是旧的”。

## 最后核对

2026-11-10，对照 `lib/Pages/**` 全量核对。
