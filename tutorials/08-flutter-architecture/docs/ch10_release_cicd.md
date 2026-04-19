# 第10章：发布与 CI/CD

## 目录

1. [构建模式](#1-构建模式)
2. [Android 发布](#2-android-发布)
3. [iOS 发布](#3-ios-发布)
4. [Web 发布](#4-web-发布)
5. [代码混淆](#5-代码混淆)
6. [Flavor / 环境配置](#6-flavor--环境配置)
7. [Fastlane 自动化](#7-fastlane-自动化)
8. [GitHub Actions CI/CD](#8-github-actions-cicd)
9. [最佳实践](#9-最佳实践)

---

## 1. 构建模式

### 1.1 三种模式

| 模式 | 编译方式 | 用途 | 命令参数 |
|------|---------|------|---------|
| Debug | JIT | 开发调试 | 默认 |
| Profile | AOT | 性能分析 | `--profile` |
| Release | AOT | 发布上线 | `--release` |

### 1.2 构建命令

```bash
# Android APK
flutter build apk --release

# Android App Bundle（推荐，Google Play 要求）
flutter build appbundle --release

# iOS
flutter build ipa --release

# Web
flutter build web --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release

# Windows
flutter build windows --release
```

### 1.3 自定义构建参数

```bash
# 自定义版本号
flutter build apk --build-name=1.2.0 --build-number=42

# 传递编译时常量
flutter build apk --dart-define=API_URL=https://api.prod.com
flutter build apk --dart-define=ENV=production

# 在代码中使用
const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost');
const env = String.fromEnvironment('ENV', defaultValue: 'development');
```

## 2. Android 发布

### 2.1 签名配置

创建 keystore：

```bash
keytool -genkey -v \
  -keystore ~/key.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias my-key-alias
```

创建 `android/key.properties`（**不要提交到 Git**）：

```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=my-key-alias
storeFile=/path/to/key.jks
```

### 2.2 配置 build.gradle

```groovy
// android/app/build.gradle

def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true       // 启用代码压缩
            shrinkResources true     // 启用资源压缩
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 2.3 构建发布包

```bash
# APK（适合直接安装）
flutter build apk --release
# 输出: build/app/outputs/flutter-apk/app-release.apk

# App Bundle（适合 Google Play）
flutter build appbundle --release
# 输出: build/app/outputs/bundle/release/app-release.aab

# 分架构 APK（减小体积）
flutter build apk --split-per-abi
# 输出: app-armeabi-v7a-release.apk
#        app-arm64-v8a-release.apk
#        app-x86_64-release.apk
```

## 3. iOS 发布

### 3.1 前置要求

- Apple Developer 账号（$99/年）
- Xcode 安装并配置
- 证书和描述文件

### 3.2 配置签名

在 Xcode 中：

1. 打开 `ios/Runner.xcworkspace`
2. 选择 Runner → Signing & Capabilities
3. 设置 Team 和 Bundle Identifier
4. 选择 Provisioning Profile

### 3.3 构建和发布

```bash
# 构建 IPA
flutter build ipa --release

# 使用 Xcode 上传
# 1. 打开 build/ios/archive/Runner.xcarchive
# 2. Xcode → Window → Organizer → Distribute App

# 或使用命令行上传
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/app.ipa \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID
```

### 3.4 TestFlight

```bash
# 使用 app-store-connect API
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/Runner.ipa \
  --apiKey $API_KEY \
  --apiIssuer $API_ISSUER
```

## 4. Web 发布

### 4.1 构建

```bash
# 默认构建（使用 canvaskit 渲染器）
flutter build web --release

# 使用 HTML 渲染器（更小的初始体积）
flutter build web --web-renderer html --release

# 自动选择渲染器
flutter build web --web-renderer auto --release

# 带基路径（部署到子目录）
flutter build web --base-href /my-app/ --release
```

### 4.2 部署到 GitHub Pages

```bash
# 构建
flutter build web --base-href /repo-name/ --release

# 部署到 gh-pages 分支
cd build/web
git init
git add .
git commit -m "Deploy to GitHub Pages"
git push --force git@github.com:user/repo.git main:gh-pages
```

### 4.3 部署到 Firebase Hosting

```bash
# 安装 Firebase CLI
npm install -g firebase-tools

# 初始化
firebase init hosting
# 设置 public 目录为 build/web

# 部署
flutter build web --release
firebase deploy --only hosting
```

## 5. 代码混淆

### 5.1 Dart 代码混淆

```bash
# 启用混淆（仅 Release 模式）
flutter build apk --obfuscate --split-debug-info=build/debug-info

# --obfuscate: 混淆 Dart 代码中的类名、方法名等
# --split-debug-info: 将调试信息分离到指定目录（用于符号化堆栈跟踪）
```

### 5.2 保存符号文件

混淆后的崩溃日志需要符号文件来还原：

```bash
# 符号文件保存在 build/debug-info/ 目录
# 务必保存这些文件！

# 使用符号文件还原堆栈
flutter symbolize \
  -i crash_log.txt \
  -d build/debug-info/
```

### 5.3 Android ProGuard

创建 `android/app/proguard-rules.pro`：

```proguard
# Flutter 相关
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 保留注解
-keepattributes *Annotation*

# 保留某些类（根据需要添加）
-keep class com.example.myapp.models.** { *; }
```

## 6. Flavor / 环境配置

### 6.1 什么是 Flavor

Flavor 允许从同一代码库构建不同版本的应用：

- **开发版**（dev）：连接测试服务器，启用调试工具
- **预发布版**（staging）：连接预发布服务器
- **正式版**（production）：连接生产服务器

### 6.2 使用 --dart-define

```bash
# 开发环境
flutter run --dart-define=ENV=dev --dart-define=API_URL=http://dev-api.example.com

# 生产环境
flutter build apk --dart-define=ENV=prod --dart-define=API_URL=https://api.example.com
```

```dart
// 在代码中读取
class AppConfig {
  static const env = String.fromEnvironment('ENV', defaultValue: 'dev');
  static const apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080',
  );

  static bool get isDev => env == 'dev';
  static bool get isProd => env == 'prod';
}
```

### 6.3 使用 --dart-define-from-file

创建配置文件（**不要提交到 Git**）：

`config/dev.json`：
```json
{
  "ENV": "dev",
  "API_URL": "http://dev-api.example.com",
  "ENABLE_LOGGING": "true"
}
```

```bash
flutter run --dart-define-from-file=config/dev.json
```

### 6.4 Android Flavor

在 `android/app/build.gradle` 中配置：

```groovy
android {
    flavorDimensions "environment"
    productFlavors {
        dev {
            dimension "environment"
            applicationIdSuffix ".dev"
            versionNameSuffix "-dev"
            resValue "string", "app_name", "MyApp Dev"
        }
        staging {
            dimension "environment"
            applicationIdSuffix ".staging"
            versionNameSuffix "-staging"
            resValue "string", "app_name", "MyApp Staging"
        }
        prod {
            dimension "environment"
            resValue "string", "app_name", "MyApp"
        }
    }
}
```

```bash
flutter run --flavor dev
flutter build apk --flavor prod --release
```

## 7. Fastlane 自动化

### 7.1 什么是 Fastlane

Fastlane 是移动应用 CI/CD 的自动化工具，可以自动化：
- 构建
- 签名
- 截图
- 发布到应用商店
- Beta 测试分发

### 7.2 安装和初始化

```bash
# 安装
gem install fastlane

# Android 初始化
cd android && fastlane init

# iOS 初始化
cd ios && fastlane init
```

### 7.3 Android Fastfile 示例

`android/fastlane/Fastfile`：

```ruby
default_platform(:android)

platform :android do
  desc "Deploy to Google Play Internal Testing"
  lane :internal do
    # 构建
    sh "cd ../.. && flutter build appbundle --release"

    # 上传到 Google Play
    upload_to_play_store(
      track: 'internal',
      aab: '../build/app/outputs/bundle/release/app-release.aab',
      json_key_file: 'play-store-key.json',
    )
  end

  desc "Deploy to Google Play Production"
  lane :production do
    sh "cd ../.. && flutter build appbundle --release"

    upload_to_play_store(
      track: 'production',
      aab: '../build/app/outputs/bundle/release/app-release.aab',
      json_key_file: 'play-store-key.json',
    )
  end
end
```

### 7.4 iOS Fastfile 示例

`ios/fastlane/Fastfile`：

```ruby
default_platform(:ios)

platform :ios do
  desc "Push to TestFlight"
  lane :beta do
    # 自动管理证书
    match(type: "appstore")

    # 构建
    sh "cd ../.. && flutter build ipa --release"

    # 上传到 TestFlight
    upload_to_testflight(
      ipa: '../build/ios/ipa/Runner.ipa',
      skip_waiting_for_build_processing: true,
    )
  end

  desc "Deploy to App Store"
  lane :release do
    match(type: "appstore")
    sh "cd ../.. && flutter build ipa --release"

    upload_to_app_store(
      ipa: '../build/ios/ipa/Runner.ipa',
      submit_for_review: true,
      automatic_release: false,
    )
  end
end
```

## 8. GitHub Actions CI/CD

### 8.1 基础 CI 工作流

`.github/workflows/ci.yml`：

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  analyze-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
          channel: 'stable'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Analyze code
        run: flutter analyze --fatal-infos

      - name: Run tests
        run: flutter test --coverage

      - name: Check formatting
        run: dart format --output=none --set-exit-if-changed .
```

### 8.2 Android 构建和发布

```yaml
name: Android Release

on:
  push:
    tags: ['v*']

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Run tests
        run: flutter test

      # 解码签名文件
      - name: Decode keystore
        env:
          KEYSTORE_BASE64: ${{ secrets.KEYSTORE_BASE64 }}
        run: echo "$KEYSTORE_BASE64" | base64 --decode > android/app/keystore.jks

      - name: Create key.properties
        run: |
          cat > android/key.properties << EOF
          storePassword=${{ secrets.STORE_PASSWORD }}
          keyPassword=${{ secrets.KEY_PASSWORD }}
          keyAlias=${{ secrets.KEY_ALIAS }}
          storeFile=keystore.jks
          EOF

      # 构建 APK 和 AAB
      - name: Build APK
        run: flutter build apk --release --obfuscate --split-debug-info=build/debug-info

      - name: Build App Bundle
        run: flutter build appbundle --release

      # 上传到 GitHub Release
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            build/app/outputs/flutter-apk/app-release.apk
            build/app/outputs/bundle/release/app-release.aab

      # 上传到 Google Play
      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_JSON }}
          packageName: com.example.myapp
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: internal
```

### 8.3 iOS 构建和发布

```yaml
name: iOS Release

on:
  push:
    tags: ['v*']

jobs:
  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Run tests
        run: flutter test

      # 安装证书
      - name: Install Apple Certificate
        uses: apple-actions/import-codesign-certs@v2
        with:
          p12-file-base64: ${{ secrets.P12_BASE64 }}
          p12-password: ${{ secrets.P12_PASSWORD }}

      - name: Install Provisioning Profile
        uses: apple-actions/download-provisioning-profiles@v1
        with:
          bundle-id: com.example.myapp
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_API_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_API_PRIVATE_KEY }}

      - name: Build IPA
        run: flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

      - name: Upload to TestFlight
        uses: apple-actions/upload-testflight-build@v1
        with:
          app-path: build/ios/ipa/Runner.ipa
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_API_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_API_PRIVATE_KEY }}
```

### 8.4 Web 部署到 GitHub Pages

```yaml
name: Deploy Web

on:
  push:
    branches: [main]

jobs:
  deploy-web:
    runs-on: ubuntu-latest
    permissions:
      pages: write
      id-token: write
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'

      - name: Build Web
        run: |
          flutter pub get
          flutter build web --release --base-href /${{ github.event.repository.name }}/

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./build/web
```

### 8.5 完整 CI/CD 流水线

```yaml
name: Full Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  # 第一阶段：代码质量检查
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
          cache: true
      - run: flutter pub get
      - run: flutter analyze
      - run: dart format --output=none --set-exit-if-changed .

  # 第二阶段：测试
  test:
    needs: quality
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
          cache: true
      - run: flutter pub get
      - run: flutter test --coverage
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info

  # 第三阶段：构建（仅 main 分支）
  build:
    needs: test
    if: github.ref == 'refs/heads/main'
    strategy:
      matrix:
        include:
          - os: ubuntu-latest
            target: apk
          - os: ubuntu-latest
            target: web
          - os: macos-latest
            target: ipa
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
      - run: flutter pub get
      - run: flutter build ${{ matrix.target }} --release
      - uses: actions/upload-artifact@v3
        with:
          name: ${{ matrix.target }}-build
          path: build/
```

## 9. 最佳实践

### 9.1 版本管理

```yaml
# pubspec.yaml
version: 1.2.3+45
#        │ │ │  │
#        │ │ │  └─ build number（每次构建递增）
#        │ │ └──── patch（修复 bug）
#        │ └────── minor（新功能，向后兼容）
#        └──────── major（破坏性变更）
```

### 9.2 .gitignore

```gitignore
# 签名文件 —— 绝对不要提交！
android/key.properties
android/app/keystore.jks
ios/fastlane/AuthKey_*.p8

# 构建产物
build/
*.apk
*.aab
*.ipa

# 环境配置
config/*.json
.env
```

### 9.3 Secrets 管理

```
# GitHub Actions Secrets 中配置：
KEYSTORE_BASE64      # Android keystore (base64 编码)
STORE_PASSWORD       # keystore 密码
KEY_PASSWORD         # key 密码
KEY_ALIAS            # key 别名
PLAY_STORE_JSON      # Google Play 服务账号
APPSTORE_API_KEY_ID  # App Store Connect API Key
APPSTORE_ISSUER_ID   # App Store Connect Issuer ID
```

### 9.4 发布检查清单

- [ ] 版本号已更新
- [ ] 所有测试通过
- [ ] `flutter analyze` 无警告
- [ ] 代码已混淆
- [ ] 调试信息已分离保存
- [ ] 隐私政策已更新
- [ ] 应用截图已更新
- [ ] 更新日志已编写
- [ ] 签名文件安全保管
- [ ] CI/CD 流水线绿色

### 9.5 应用体积优化

```bash
# 查看 APK 分析
flutter build apk --analyze-size

# 分架构构建
flutter build apk --split-per-abi

# 移除未使用的资源
# 在 build.gradle 中启用 shrinkResources

# 使用 deferred components（按需加载）
# 使用 --tree-shake-icons 移除未使用的图标字体
flutter build apk --tree-shake-icons
```

---

## 总结

| 阶段 | 工具/命令 |
|------|----------|
| 构建 | `flutter build apk/ipa/web` |
| 签名 | keystore (Android) / Certificate (iOS) |
| 混淆 | `--obfuscate --split-debug-info` |
| 多环境 | `--dart-define` / `--flavor` |
| 自动化 | Fastlane |
| CI/CD | GitHub Actions |
| 发布 | Google Play / App Store / GitHub Pages |

一个成熟的 Flutter 项目应该有完整的 CI/CD 流水线，从代码提交到应用发布全程自动化。这不仅提高了发布效率，也确保了每次发布的质量和一致性。

**恭喜！你已经完成了 Flutter 架构教程的所有章节！** 🎉
