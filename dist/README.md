# dist · 可安装包

`demo_pages` 的两份构建产物，对应 `pubspec.yaml` 的 `version: 1.1.0+2`。

| 文件 | 用途 | 说明 |
|---|---|---|
| `demo_pages-v1.1.0-build2-release.apk` | 发给别人装 / 上架 | AOT 编译，走 `android/key.properties` 里的 release 签名 |
| `demo_pages-v1.1.0-build2-debug.apk` | 自己调试、热重载 | JIT + 断言，可用 `flutter attach` 连 |

## 签名

release 包用仓库外的一份 keystore 签名（`android/upload-keystore.jks`，不进版本库）：

```
CN=Itchi Demo Pages, OU=Mobile, O=Itchi Technology Limited, L=Hong Kong, ST=Hong Kong, C=HK
SHA-256  d03e648f016ab61ca0cefaec10929e7c6cfad175f6988a17e316bc2fca88daeb
SHA-1    93537ad2108a841a48310cd15a2f1211d80e996e
versionCode 2 / versionName 1.1.0
```

密码与别名在 `android/key.properties`（同样不进版本库）。换机器时把这两个文件一起带走，
否则后续版本无法覆盖安装。

## 重新构建

```powershell
cd E:\flutter\demo_pages
flutter build apk --release
flutter build apk --debug
```

产物在 `build\app\outputs\flutter-apk\`，复制到 `dist\` 即可。
`dist/*.apk` 已在 `.gitignore` 里 —— 二进制不进仓库，需要时现场构建。
