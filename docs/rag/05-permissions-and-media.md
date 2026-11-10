# 05 · 权限与图片

一句话：**先问权限，再开 picker；拒绝就给出口，但永远允许“不拍照继续”。**

## 依赖与平台声明

| 位置 | 内容 |
| --- | --- |
| `pubspec.yaml` | `image_picker: ^1.2.4`、`permission_handler: ^13.0.2` |
| `android/app/src/main/AndroidManifest.xml` | `CAMERA`、`READ_MEDIA_IMAGES`、`<uses-feature android:name="android.hardware.camera" android:required="false"/>` |
| `ios/Runner/Info.plist` | `NSCameraUsageDescription`、`NSPhotoLibraryUsageDescription`、`CFBundleLocalizations` |

Android 13+ 的相册实际走系统 Photo Picker，声明 `READ_MEDIA_IMAGES` 是按课件要求保留的（也保证 `Permission.photos` 有东西可查）。`uses-feature` 必须 `required=false`，否则没有摄像头的设备直接装不上。

## 权限三态

`permission_handler` 的状态不止“给/不给”：

1. `granted` → 直接开 picker。
2. `denied`（首次）→ `request()`；用户同意就继续。
3. `permanentlyDenied`（拒绝过且勾了“不再询问”）→ `request()` 不会再弹窗，只能跳系统设置。

代码里统一处理：`status.isGranted` 为假就 `request()` 一次，仍为假 → 弹 `photoPermissionDialog`（`permissionCancel` / `permissionOpenSettings`），后者调 `openAppSettings()`。

## 选图流程

`AddPage._pickPhoto(ImageSource source)`：

1. 按来源选权限：相机 `Permission.camera`，相册 `Permission.photos`。
2. `pickImage(source:, maxWidth: 1600, imageQuality: 85)` —— 压缩在 picker 里完成，别在 Dart 侧再转一次。
3. `AppScope.of(context).photos.import(picked.path)` 复制进 `photos/`，拿到**文件名**。
4. `setState(() => _controller.setPhoto(name))`；失败弹 `dialog_photo_failed`。

> 顺序很重要：先 import 再 setState。反过来的话，预览会闪一下空白。

## 清理责任

| 时机 | 谁负责 |
| --- | --- |
| 保存成功 | 文件名进 entry，`_uncommitted` 里移除 |
| 点「移除照片」 | 立刻删文件，再清 UI |
| 未保存就返回 | `dispose()` 删掉所有 `_uncommitted`；`HomePage._openAdd` 拿到 `null` 时再扫一遍孤儿 |
| App 被杀 | 下次启动 `purgeOrphanPhotos()` |

不清理的后果很实在：一次“选图→返回”就留下 40 KB，用户不会知道去哪删。

## 展示

- 卡片缩略图：`Image.file(..., cacheWidth: 168)`。不设 `cacheWidth` 时 Flutter 会按原图解到内存，一张 1600px 照片 ≈ 3 MB/卡。
- 详情大图：`AspectRatio(4/3)` + `BoxFit.cover`，无图时占位 `detailPhotoPlaceholder`。
- 回退 `errorBuilder`：文件被外部删掉时不崩，显示断裂图标。

## iOS 没有验证环境

`ios/` 目录是 `flutter create --platforms=ios .` 补出来的，只做过 `Info.plist` 配置，构建需要 macOS。这段是“配置到位但未在真机验证”的状态，别当成已验证。

## 最后核对

2026-11-10，对照 `AddPage.dart`、`PhotoStore`、两个平台的配置核对。
