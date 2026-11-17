# 07 · 坑与铁律

每条都真踩过。按“症状 → 原因 → 修法”记。

## 1. 三条种子拿到同一个 id

**症状**：点第二张卡片，打开的是第一条；删一条把三条一起删了。
**原因**：早期用 `microsecondsSinceEpoch` 生成 id，连续构造三次拿到同一微秒。
**修法**：模型直接不要 id，列表用对象身份（`identical`）定位。真需要唯一名（照片）时，时间戳后面拼自增序号。

## 2. 测试里真实文件 IO → `pumpAndSettle timed out`

**症状**：widget 测试挂 10 分钟后超时，报 `pumpAndSettle timed out`。
**原因**：文件 future 挂在真实事件循环上，widget 测试跑的是假时钟，永远等不到。
**修法**：业务代码给每个服务留内存实现（`JournalStore.inMemory()`、`PhotoStore.inMemory()`）；确实要测真实文件的，用 `tester.runAsync` 把**整个动作**（包括 tap 和之后的等待）包进去，见 `test/photo_store_test.dart` 的 `_tapAndFlush`。

## 3. 单例被上一个测试污染

**症状**：单独跑过，整套跑不过；列表里多出上次的条目。
**修法**：`setUp` 里重建控制器 + `SharedPreferences.setMockInitialValues({})`；不要在测试之间复用 controller。

## 4. `tester.tap` 只警告不报错

**症状**：测试“通过”但什么都没发生；或者报 `Found 0 widgets with type "CupertinoNavigationBarBackButton"`。
**原因**：目标控件在视口外，`tap` 只打 warning。
**修法**：先 `await tester.ensureVisible(finder)` 或用 `tester.pageBack()` 走系统返回；AddPage 作为根页时没有返回键，要 `Navigator.pop()`。

## 5. 子页改了数据，列表没变

**原因**：`DetailPage` 只改自己的 `_entry`，没人通知列表。
**修法**：`onUpdated` 回调 → `controller.replaceEntry(old, updated)`，且用 `identical` 找位置（对象重新构造后 `==` 也不一定对）。

## 6. `copyWith` 让“删照片”失效

**症状**：编辑时点移除照片，保存后照片还在。
**原因**：`copyWith(photoPath: null)` 的 `null` 表示“不改这个字段”。
**修法**：编辑保存时**手工构造**新 `JournalEntry`，只沿用 `createdAt`。

## 7. 清空后条数还是旧数字

**症状**：`已使用 0 KB` 了，下面还写着 `6`。
**原因**：`SettingsPage.entryCount` 传的是 `int`，值在构造时定格。
**修法**：传 `int Function()`，页面每次 build 时再取。

## 8. 存储大小清了不显示 0

**原因**：四舍五入把 600 字节算成 `1 KB`。
**修法**：`formatStorageSize` 向下取整。

## 9. `Dismissible` 删错条目

**原因**：用 `key: ValueKey(index)`，删完索引全错位。
**修法**：`key: ObjectKey(entry)`。

## 10. 中文写进代码后变乱码

**症状**：`read` 报 `invalid UTF-8 text`。
**原因**：用 PowerShell `(Get-Content -Raw) -replace … | Set-Content` 批量替换中文，默认编码把 UTF-8 写坏。
**修法**：改文案走 edit / write 工具，或 Python `encoding='utf-8'`；纯 ASCII 文件才可以放心用 PowerShell 替换。

## 11. ARB 只改了一份

**症状**：切到中文还是英文。
**修法**：三份 ARB 必须同键同改，然后 `flutter gen-l10n`；生成物也在仓库里，一并提交。

## 12. 缩略图吃内存

**原因**：`Image.file` 默认按原始分辨率解码，1600px 图 ≈ 3 MB/卡。
**修法**：`cacheWidth: (size * 3).round()`。

## 13. 权限被永久拒绝后怎么点都没反应

**原因**：`request()` 在 `permanentlyDenied` 下不再弹窗。
**修法**：`isGranted` 为假时一律提供 `openAppSettings()` 出口，并允许不拍照继续。

## 14. headless 截图只有一半内容

**原因**：headless Chrome 最小视口约 500px，`--window-size=420,880` 会按 800 排版再裁切。
**修法**：截 900×700，或用 iframe 壳页固定 420 宽。

## 15. 模拟器“飞天”

**症状**：窗口比屏幕还高，底部一截在屏外，点不到。
**原因**：AVD 1080×2400 + `showDeviceFrame=yes` + 软件渲染。
**修法**：见 06 的 AVD 配置；窗口句柄在 `qemu-system-x86_64` 上，必要时 `SetWindowPos` 摁回屏内。

## 16. 改了 `version:` 却还是旧版本号

**症状**：pubspec 明明写了 `1.1.0+2`，Settings 仍显示 `1.0.0`、`build/web/version.json` 也是旧的。
**原因**：`package_info_plus` 读的是**打包时写进产物里的值**，刷新页面 / 热重载都不算重新构建。
**修法**：`flutter pub get` → 重新 `flutter run` / `flutter build`；web 再核对 `build/web/version.json`。

## 17. 新增一段内容把底部的按钮挤出折叠线

**症状**：`find.byKey(Key('SettingsBack'))` 突然 `findsNothing`，点不到。
**原因**：Settings 页加了 About 段，600px 测试视口装不下，`ListView` 未滚到底。
**修法**：测试里 `tester.scrollUntilVisible(finder, 120, scrollable: find.byType(Scrollable).first)`；
不要为了迁就测试把按钮挪到中间 —— 真机上用户同样要滚。

## 18. 原生插件的能力在别的平台上是「静默不可用」

**症状**：接了 `itchi_flutter_duo_layout` 之后，Android/Web 上什么都不发生；怀疑没接上。
**原因**：插件 `plugin.platforms` 里只有 `ios`，其他平台返回 `unsupportedPlatform`，这是设计。
**修法**：所有调用点都按「可能不可用」写（`railActive` 判据 + catch），并给非 iOS 一条完整可用的路径；
测试里用假 `DuoBridge` 覆盖 available / unsupported / 抛异常三种情况。

## 19. `Image.file` 放进 widget 测试会挂住不返回

**症状**：`flutter test` 跑到某个 `testWidgets` 就停住，几分钟不出结果，`flutter_tester` 进程还在。
**原因**：`Image.file` 订阅了真实的 `ImageStream`，测试的 fake async 环境里解码永远走不完，
teardown 一直等它。
**修法**：不要在 widget 测试里喂真实图片文件 —— 只测「无图时不渲染额外层」这类逻辑分支；
一定要测真实解码就用 `tester.runAsync(...)`，或者给组件注入 `ImageProvider`。

## 铁律

1. `flutter analyze` 不干净不动下一步。
2. 每个 bug 修完补一条测试，用 AC 编号命名。
3. 子页改数据 → 必须有回写路径。
4. 破坏性操作 → 双重确认 + 完成后明确反馈。
5. 文件只存文件名，路径每次算。
6. 文档与代码不一致 → 改文档，不改“记忆”。

## 最后核对

2026-11-17，18 条全部仍适用（16–18 为 Session 4 新增）。
