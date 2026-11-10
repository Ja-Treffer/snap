# 02 · 数据与持久化

一句话：**一条记录一个 JSON 对象，照片只存文件名；写入走原子替换，坏文件不删只改名。**

## 模型

`lib/Models/JournalEntry.dart`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `title` | `String` | 保存时若为空则落 `Untitled`（文案来自 ARB，不在这里硬编码） |
| `note` | `String` | 可以为空字符串 |
| `createdAt` | `DateTime` | 编辑时**必须沿用**原值 |
| `photoPath` | `String?` | 只是**文件名**，如 `p-mwkudl8-0.jpg` |

- `copyWith({title, note, photoPath})` 只覆盖传入的字段。
- `toJson()` 用 `toIso8601String()`；`fromJson` 对缺失字段、非法日期做降级而不是抛异常。
- 没有 `id`。列表用对象身份（`identical`）定位，删了再加回来就是新对象。理由：课堂规模下 id 只会增加“生成策略”这个额外问题，而当初就是它撞过车（详见 07 第 1 条）。

## 记录存储

`lib/Utils/journal_store.dart`

- 文件：`<documents>/journal.json`，结构 `{"version": 1, "entries": [...]}`。
- `exists()` / `load()` / `save()` / `sizeInBytes()` / `deleteFile()`。
- **原子写**：先写 `journal.json.tmp` → 删旧文件 → `rename`。中途断电最多丢这一次改动，不会得到半个 JSON。
- **坏文件隔离**：`load()` 解析失败时把文件改名成 `journal.json.bak-<毫秒>`，返回空列表。用户数据不丢，App 不崩。
- `deleteFile()` 会连 `.tmp` 与所有 `.bak-*` 一起清掉（“清空全部”用它）。
- `JournalStore.inMemory()` 给测试用，不碰磁盘。

## 照片存储

`lib/Utils/photo_store.dart`

- 目录：`<documents>/photos/`，启动时 `ensureReady()` 建好并缓存，之后 `pathOf(fileName)` 是**同步**的（画的时候不能 await）。
- `import(sourcePath)`：从系统缓存目录**复制**一份进来，命名 `p-<base36 毫秒>-<序号>.jpg`，返回文件名。
  - 为什么复制：相机/相册给的是缓存路径，系统随时会清；而且绝对路径重装就全废。
  - 为什么只存文件名：目录变、包名变、迁移到另一台机器时，只有文件名是稳定的。
- `delete` / `clearAll` / `usedBytes` / `deleteUnreferenced(keep)`。
- `delete` 失败会重试一次（Windows 上刚画过的图还占着句柄），仍失败就留给下次启动的回收。

## 孤儿照片回收

三个入口，缺一不可：

1. 启动 `load()` 之后：`purgeOrphanPhotos()`，删掉没有任何 entry 指向的文件。
2. Add 页取消返回（`_openAdd` 拿到 `null`）：同样扫一遍。
3. Add 页里点「Remove photo」：立刻删掉那一张（它还没被任何 entry 引用）。

App 被杀在“复制完照片、还没保存”之间，靠第 1 条收拾。

## 设置存储

`lib/Utils/app_settings.dart`，`shared_preferences`，键 `app.locale`，值 `system` / `en` / `zh` / `zh_Hant`。启动时 `await load()` 之后才 `runApp`，所以首帧语言就是对的，不会闪一下英文。

## 测试用内存实现

| 真实 | 测试 |
| --- | --- |
| `JournalStore()` | `JournalStore.inMemory()` |
| `PhotoStore()` | `PhotoStore.inMemory()` |
| `AppSettings()` | `AppSettings()` + `SharedPreferences.setMockInitialValues({})` |

**纪律**：widget 测试里出现真实文件 IO，`pumpAndSettle` 会直接超时——因为文件 future 挂在真实事件循环上，而 widget 测试跑的是假时钟。要测真实文件就用 `tester.runAsync` 把整个动作包进去（见 `test/photo_store_test.dart` 的 `_tapAndFlush`）。

## 最后核对

2026-11-10，对照 `lib/Models`、`lib/Utils` 全量核对。
