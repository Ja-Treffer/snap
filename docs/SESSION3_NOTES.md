# Session 3 学习笔记 —— 同样一件事，通用做法与 Flutter 做法

> 来源：`Itchi_Flutter_Session3.pptx`（36 页）。
> 交付代码：`E:\flutter\demo_pages`（EduSnap）。契约见 `docs/PROJECT_SPEC.md` §13。

Session 3 表面上在讲四个功能（权限、相机相册、本地存储、多语言），
实际在讲**一个 App 从"能跑"走向"能交付"必须补的四块地基**。
每一块都能拆成"任何平台都得想清楚的事"和"Flutter 里具体怎么落"。

---

## 1. 权限（Part 01）

### 通用开发视角

1. **权限不是功能，是契约**。相机、相册、通知、定位，都是操作系统的资源，
   应用只能"申请"，不能"拥有"。
2. **按需申请，别开机就申请**。首启就弹三个权限框，用户的第一反应是"这 App 想干嘛"，
   拒绝率最高。正确时机是**用户点了那个按钮的一瞬间**。
3. **拒绝是正常路径，不是异常**。三种状态要分清楚：
   - 还没问过 → 问；
   - 问过被拒 → 解释为什么需要，给一个"去设置里开"的按钮；
   - 永久拒绝（不再弹框）→ 只能引导去系统设置。
4. **降级要设计好**。没有相机权限，用户依然应该能写纯文字日志。
   权限失败不是流程终点，只是少了一个能力。

### Flutter 里的落法

```dart
final Permission permission =
    source == ImageSource.camera ? Permission.camera : Permission.photos;

PermissionStatus status = await permission.status;      // 先看现状，别急着 request
if (!status.isGranted) status = await permission.request();
if (!status.isGranted) {
  // 弹自己的对话框，而不是什么都没发生
  showDialog(... permissionOpenSettings → openAppSettings() ...);
  return;
}
```

- 包：`permission_handler`。
- 平台侧必须写描述文案，否则系统直接杀掉进程（iOS 尤甚）：
  - iOS `ios/Runner/Info.plist`：`NSCameraUsageDescription`、`NSPhotoLibraryUsageDescription`；
  - Android `AndroidManifest.xml`：`CAMERA` + `<uses-feature android:required="false">`。
- 本机实测坑：`permission_handler_android` 13.x 的 AAR 要求 **`compileSdk = 37`**，
  而 Flutter 默认还是 36 → Gradle 报 `CheckAarMetadataWorkAction` 失败。
  在 `android/app/build.gradle.kts` 里写死 `compileSdk = 37` 即可（本机已装 `platforms/android-37.0`）。

---

## 2. 相机 / 相册（Part 02）

### 通用开发视角

- 拿到的是"一张图"，要做四件事：**压缩 → 复制到自己的目录 → 存路径 → 显示**。
- 绝不要长期持有系统返回的临时路径：相册里的图会被用户删，相机缓存会被系统清。
- 数据库里存**文件名**比存绝对路径好：iOS 每次更新 App 容器路径都会变。

### Flutter 里的落法

```dart
final XFile? picked = await ImagePicker().pickImage(
  source: source,
  maxWidth: 1600,      // 先压缩再落盘，省空间也省内存
  imageQuality: 85,
);
final String? stored = await photos.import(picked.path); // 复制成 p-xxx.jpg
```

- `PhotoStore.import()` 用 `getApplicationDocumentsDirectory()` 下的 `photos/`，
  返回**文件名**；`pathOf(fileName)` 是同步的，方便 build 里直接用。
- 显示用 `Image.file(File(path))`，没照片时给占位方块而不是留白 ——
  卡片高度必须稳定，否则列表会跳。

---

## 3. 本地存储（Part 03）

### 通用开发视角

| 问题 | 好答案 | 坏答案 |
|---|---|---|
| 存什么格式 | 带 `version` 字段的结构化数据 | 直接 `toString()` 拼字符串 |
| 怎么写 | 先写 `.tmp`，再 rename 覆盖（原子写） | 直接覆盖，写到一半断电就全没了 |
| 数据坏了怎么办 | 隔离成 `.bak`，以空数据启动 | 崩溃，或者清空覆盖用户数据 |
| 首次启动 | 有文件读文件，没文件才播种样例 | 每次都播种 → 用户删光了重开又长回来 |

### Flutter 里的落法

- 两条路线，课件都接受：
  1. `shared_preferences`（键值对，适合偏好设置，不适合列表）；
  2. **JSON 文件 + `path_provider`**（本项目选的，因为条目里还有照片路径）。
- 写入时机：**每次列表变化就写**（add / delete / edit），别等 `dispose`，
  移动端进程随时可能被杀。
- 测试铁律：widget 测试里的时钟是假的，真实 `File` 的 Future 永远不完成
  → `pumpAndSettle` 超时。所以存储层必须有 `inMemory()` 构造给测试注入。

---

## 4. 多语言（Part 04）

### 通用开发视角

1. **文案里不能拼字符串**。`'Created on ' + date` 在中文里会变成
   "Created on 2026年10月1日" 这种半英半中的怪东西。
   正确做法是整句模板 + 占位符：`Created on {date}` / `{date} 建立`。
2. **键名要有规律**：`page_item` / `功能_对象`，例如 `homepage_title`、`btn_cancel`、
   `settings_storage_used`。键名乱，三个月后没人敢删。
3. **语言是用户偏好，要能存**。系统语言只是默认值，用户手动选过就该记住。
4. **别只做"翻译"，还要做"排版"**：德语长、中文短，按钮宽度不能写死。

### Flutter 里的落法

- `pubspec.yaml` 加 `flutter_localizations` + `intl`，开 `flutter: generate: true`；
- `l10n.yaml` 指定 `arb-dir: lib/l10n`、模板 `app_en.arb`、`output-class: AppLocalizations`；
- 三个 ARB：`app_en.arb` / `app_zh.arb` / `app_zh_Hant.arb`，带 `@` 元数据描述占位符类型；
- `flutter gen-l10n` 生成 `app_localizations*.dart`（zh_Hant 会折进 zh 文件里作为子类）；
- `MaterialApp(locale: settings.locale, localizationsDelegates: ..., supportedLocales: ...)`；
- 用法：`AppLocalizations.of(context).entry_created_on(dateText)`，全程不手写中文。

日期格式化用 `intl` 的 `DateFormat.yMMMd(localeName)` ——
**按语言格式化日期**，比 `toString()` 靠谱得多。

---

## 5. Settings 页与破坏性操作（Challenge）

- 存储用量这种数字要**向下取整**：651 字节显示 `0 KB`，否则"已清空"和"还有 651 字节"
  两种文案会让用户以为没删干净。
- 清空是**不可逆操作**，两次确认（第一次说明后果，第二次确认执行），
  且清空要连照片一起删，不能只清 JSON。
- 危险按钮放在页面底部、用 tonal 样式，别和正常操作并排。

---

## 6. 这一节真正的"通用工程技能"

| 技能 | 在这一节里长什么样 |
|---|---|
| 依赖管理 | 一次加 5 个包，每个都要想清楚"能不能不用" |
| 平台差异 | iOS 写 plist，Android 写 manifest，行为还可能不同 |
| 数据契约 | 模型加字段要考虑老数据（`fromJson` 全字段可缺） |
| 可测试性 | 存储/时钟/图片选择器都要能注入替身 |
| 国际化 | 从第一天就写 key，比事后补便宜十倍 |
| 破坏性操作 | 双重确认 + 明确后果 + 不可逆提示 |

## 7. 自检清单（下次做同类功能直接照抄）

- [ ] 权限：三种状态都处理了吗？拒绝后用户还能继续用吗？
- [ ] 选图：压缩了吗？复制到自己的目录了吗？存的是文件名还是绝对路径？
- [ ] 存储：原子写了吗？坏了会隔离吗？首启播种只播一次吗？
- [ ] i18n：还有硬编码文案吗？（`Untitled`、`No note` 这类兜底最容易漏）
- [ ] 占位符：语序不同的语言读起来还顺吗？
- [ ] 设置页：语言选择重启后还在吗？清空真的把照片也删了吗？清空后显示 0 KB 吗？
- [ ] 测试：有没有用真实文件 IO 把 `pumpAndSettle` 卡死？
