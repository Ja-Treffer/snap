# 开发手册

给“下一次打开这个工程”的人（包括我自己）。想知道某个细节为什么这么写，去 `docs/rag/`；这里只讲**怎么干活**。

## 一、开工前 5 分钟

```powershell
cd E:\flutter\demo_pages
flutter --version            # 3.47.9 / Dart 3.13.7
flutter analyze              # 必须是 No issues found!
flutter test                 # 必须是 All tests passed!
```

三条都绿才动手。有一项红着改代码，等于在雾里开车。

先读三份文档，顺序固定：

1. `docs/rag/README.md` —— 检索入口，按症状跳转。
2. `docs/PROJECT_SPEC.md` —— 当前范围与验收标准（AC 编号）。
3. 本文件 —— 流程与纪律。

## 二、改一个功能的标准动作

1. **改文档**：`PROJECT_SPEC.md` 的需求表加一行，验收标准加一条 `AC-xx`（可判定的句子，不是“更友好”）。
2. **写测试**：先写会失败的那条，测试名带 `AC-xx`。
3. **改代码**：只动让测试变绿所需的最小面。
4. **跑三绿**：`flutter analyze` / `flutter test` / 至少一次 `flutter build apk --debug`。
5. **补文档**：`docs/rag/` 里对应篇目 + `CHANGELOG.md` 加一行。
6. **交付说明**：改了哪些文件、新增哪些 AC、验证到什么程度（单测/模拟器/仅构建）。

## 三、分层纪律（速查）

| 想加的东西 | 放哪 |
| --- | --- |
| 新字段 | `Models/JournalEntry.dart` + `toJson`/`fromJson`/`copyWith` 三件套 |
| 新页面 | `Pages/<Name>/<Name>Page.dart` + `<Name>PageController.dart`（PascalCase，课件要求） |
| 复用 UI | `Component/<Name>/<Name>.dart`，只接收算好的值与回调 |
| 存储/格式化/注入 | `Utils/` |
| 文案 | `lib/l10n/*.arb` 三份同改 + `flutter gen-l10n` |

禁止：`Pages/` 里直接 `File(...)`、`Component/` 里 `Navigator.push`、`Models/` 里出现 `flutter/material.dart`。

## 四、测试怎么写

- 一律注入内存实现：`JournalStore.inMemory()`、`PhotoStore.inMemory()`、`SharedPreferences.setMockInitialValues({})`。
- 真实文件 IO 用 `tester.runAsync` 包住动作（见 `test/photo_store_test.dart` 的 `_tapAndFlush`），否则 `pumpAndSettle` 必超时。
- 控件用 `Key` 找，不用文案（文案会翻译）。
- 断言“看不到”时注意下层路由是 offstage 的，`find` 找不到不代表没渲染。

## 五、坑速查（详见 `docs/rag/07-pitfalls.md`）

1. 对象身份 vs id：列表用 `identical`，别造 id。
2. `copyWith` 的 `null` 是“不改”，删字段要手工构造新对象。
3. 子页改数据必须有 `onUpdated` 回写。
4. 破坏性操作双重确认。
5. 文件只存文件名。
6. 缩略图 `cacheWidth`。
7. 三份 ARB 缺一会静默 fallback。
8. 不要用 PowerShell 批量替换中文。

## 六、提交与仓库

- 远端：`https://github.com/sdhjahjdsa1213/snap`，主线 `main`。
- **不擅自 `git commit` / `git push`**，要主人明确开口。
- 截图、`docs/*.png`、`docs/m1-*.json` 已在 `.gitignore` 里，别硬加。

## 七、收尾清单

- [ ] `flutter analyze` 干净
- [ ] `flutter test` 全绿（含新增 AC）
- [ ] `flutter build apk --debug` 通过
- [ ] `PROJECT_SPEC.md` 的需求表 / AC / 边界表已同步
- [ ] `docs/rag/` 对应篇目已更新，并改「最后核对」日期
- [ ] `docs/rag/CHANGELOG.md` 加一条
- [ ] 有新的通用经验 → 写进 `flutter-dev` 技能，不只留在这次对话里
