# Apollo 11 AGC — 桌面版（WebView2 套壳 + 增强）

将 [sqdcz/apollo11-agc](https://github.com/sqdcz/apollo11-agc)（阿波罗11号制导计算机网页模拟器）封装为 Windows 桌面应用，并**增强了月面漫游手感**。

> **原始游戏版权归 sqdcz 所有**（MIT 或见原仓库）。本仓库仅包含桌面套壳代码与对游戏 JS 的少量增强补丁。

## 桌面版功能

- 原生窗口（wry / WebView2），无浏览器地址栏
- 内置本地 HTTP 服务加载游戏（原样，file:// 的 CORS 问题已绕过）
- 带图标、版本信息
- NSIS 安装程序（可选安装位置 + 卸载程序）

## 对游戏的增强（`modified-web/` + `apollo11_app.js.patch`）

| 增强 | 说明 |
|------|------|
| **月球车物理重制** | 车头方向修正（原版按前进会横着走——模型车头朝 +x 但移动用 +z）；平滑加速/刹车/低摩擦滑行；转向需速度；第三人称平滑跟随镜头 |
| **宇航员步行模式** | 新增：Tab 键或按钮在「月球车驾驶」⇄「宇航员步行」切换；宇航员 WASD 控制 + 走路动画（腿/手摆动）+ 第三人称镜头 |
| **月面行走动画** | 出舱章节的宇航员从"滑动"改为走路动画（腿/手臂摆动、朝向行进方向） |
| **醒目提示** | 漫游界面顶部脉冲提示条，显示切换方式 |

## 桌面版构建

```bash
# WSL 交叉编译
export RC=x86_64-w64-mingw32-windres
cargo build --release --target x86_64-pc-windows-gnu
# 产物: target/x86_64-pc-windows-gnu/release/Apollo11AGC.exe

# 安装包
makensis installer.nsi
```

需要 WebView2Loader.dll（x64，位于构建 target 的 build/webview2-com-sys/out/x64/）与 `web/` 素材目录（从原仓库复制 + 应用本仓库的修改）。

## 目录结构

```
├── src/main.rs          # 套壳主程序（本地 HTTP 服务 + WebView2 窗口）
├── Cargo.toml
├── build.rs             # 图标/版本资源嵌入（windres）
├── app.rc / app.ico     # Windows 资源
├── installer.nsi        # NSIS 安装脚本
├── apollo11_app.js.patch # 对原游戏 JS 的修改补丁（diff -u）
└── modified-web/        # 修改后的 apollo11_app.js（可直接替换原文件）
```

## 使用方法

1. 从 [原仓库](https://github.com/sqdcz/apollo11-agc) 下载游戏文件
2. 用本仓库 `modified-web/apollo11_app.js` 替换原文件（或应用 patch）
3. 把游戏文件放进 `web/` 目录，和 Apollo11AGC.exe 同目录运行即可