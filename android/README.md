# Apollo 11 AGC — 安卓版

将 [sqdcz/apollo11-agc](https://github.com/sqdcz/apollo11-agc) 网页游戏封装为 Android APK（WebView 套壳）。

## 特性

- 全屏横屏沉浸式（`sensorLandscape`，隐藏状态栏/导航栏）
- WebView 加载 `assets/web/`（file:// + 允许跨域，绕过 CORS）
- 返回键：先 WebView 后退，无历史则退出
- 保持屏幕常亮
- 内置图标（从游戏封面生成）

## 目录结构

```
├── AndroidManifest.xml
├── src/com/sqdcz/apollo11agc/MainActivity.java   # WebView 套壳
├── res/                                           # 图标 + 字符串
├── build-apk.ps1                                  # 手动构建脚本（aapt2+javac+d8+zipalign+apksigner）
└── (assets/web/ 放游戏文件，从原仓库复制 + 应用桌面版仓库的增强补丁)
```

## 构建方法（无需 Android Studio/Gradle）

依赖：JDK 11+、Android SDK（build-tools 36.x + platform android-34）

```powershell
powershell -ExecutionPolicy Bypass -File build-apk.ps1
# 产物: Apollo11AGC.apk
```

脚本流程：aapt2 compile → aapt2 link → javac → d8 → 打包 → zipalign → apksigner（debug 签名）。

## 注意

- APK 使用 **debug 签名**（测试用）。正式分发需自建 release keystore。
- 游戏文件不包含在本仓库（版权归原作者），请从[原仓库](https://github.com/sqdcz/apollo11-agc)获取后放入 `assets/web/`。