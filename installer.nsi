; Apollo 11 AGC 桌面版安装程序（NSIS）
!define APP_NAME "Apollo 11 AGC"
!define APP_VERSION "1.2.0"
!define APP_EXE "Apollo11AGC.exe"

Name "${APP_NAME} ${APP_VERSION}"
OutFile "G:\Apollo11AGC\Apollo11AGC-Setup.exe"
InstallDir "G:\Apollo11AGC"
InstallDirRegKey HKLM "Software\Apollo11AGC" "InstallDir"
RequestExecutionLevel admin
SetCompressor /SOLID lzma
Unicode true

VIProductVersion "1.2.0.0"
VIAddVersionKey "ProductName" "${APP_NAME}"
VIAddVersionKey "FileDescription" "Apollo 11 AGC 阿波罗11号制导计算机模拟器（桌面版）"
VIAddVersionKey "FileVersion" "${APP_VERSION}"
VIAddVersionKey "LegalCopyright" "Original game: sqdcz / Desktop wrapper: 绪山真寻"
VIAddVersionKey "ProductVersion" "${APP_VERSION}"
VIAddVersionKey "CompanyName" "sqdcz / 绪山真寻 (桌面封装)"

!include "MUI2.nsh"

; 安装包/程序图标
Icon "G:\Apollo11AGC\app.ico"
UninstallIcon "G:\Apollo11AGC\app.ico"

!define MUI_WELCOMEPAGE_TITLE "欢迎安装 ${APP_NAME}"
!define MUI_WELCOMEPAGE_TEXT "Apollo 11 AGC 是阿波罗11号制导计算机（Apollo Guidance Computer）的网页模拟游戏（原项目 github.com/sqdcz/apollo11-agc）。$\r$\n$\r$\n本安装包只是桌面封装：核心代码和素材（Three.js 3D 地球/月球、AGC 模拟逻辑）原样保留，未做任何修改。$\r$\n$\r$\n增强：月球车驾驶手感重制（车头方向修正/平滑物理/第三人称镜头）、宇航员步行模式（Tab 或按钮切换）、月面行走动画。$\r$\n$\r$\n点击「下一步」继续。"

!define MUI_DIRECTORYPAGE_TEXT_TOP "请选择安装位置（默认 G:\Apollo11AGC）。"
!define MUI_FINISHPAGE_TITLE "安装完成"
!define MUI_FINISHPAGE_TEXT "${APP_NAME} 已安装完成。$\r$\n$\r$\n桌面双击「Apollo 11 AGC」启动。"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "SimpChinese"

Section "安装 Apollo 11 AGC" SecMain
  SetOutPath "$INSTDIR"
  File "G:\Apollo11AGC\Apollo11AGC.exe"
  File "G:\Apollo11AGC\WebView2Loader.dll"
  SetOutPath "$INSTDIR\web"
  File /r "G:\Apollo11AGC\web\*"

  ; 快捷方式
  CreateDirectory "$SMPROGRAMS\Apollo 11 AGC"
  CreateShortCut "$SMPROGRAMS\Apollo 11 AGC\Apollo 11 AGC.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\Apollo11AGC.exe" 0
  CreateShortCut "$SMPROGRAMS\Apollo 11 AGC\卸载 Apollo 11 AGC.lnk" "$INSTDIR\uninstall.exe"
  CreateShortCut "$DESKTOP\Apollo 11 AGC.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\Apollo11AGC.exe" 0

  ; 卸载信息
  WriteUninstaller "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "Software\Apollo11AGC" "InstallDir" "$INSTDIR"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Apollo11AGC" "DisplayName" "${APP_NAME}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Apollo11AGC" "DisplayVersion" "${APP_VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Apollo11AGC" "Publisher" "sqdcz (原项目) / 桌面封装"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Apollo11AGC" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Apollo11AGC" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Apollo11AGC" "NoRepair" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Apollo11AGC" "EstimatedSize" 4000
SectionEnd

Section "Uninstall"
  ; 先结束运行中的应用（含 WebView2 子进程），否则文件被占用删不掉
  nsExec::ExecToLog 'taskkill /f /im Apollo11AGC.exe'
  Sleep 1200
  nsExec::ExecToLog 'taskkill /f /im msedgewebview2.exe /fi "WINDOWTITLE eq *Apollo*"'
  Sleep 800
  Delete "$INSTDIR\${APP_EXE}"
  Delete "$INSTDIR\WebView2Loader.dll"
  Delete "$INSTDIR\uninstall.exe"
  Delete "$INSTDIR\web\*.*"
  RMDir /r "$INSTDIR\web"
  RMDir "$INSTDIR"
  ; 若仍被占用，注册重启后删除
  RMDir /r "$INSTDIR"
  Delete "$SMPROGRAMS\Apollo 11 AGC\Apollo 11 AGC.lnk"
  Delete "$SMPROGRAMS\Apollo 11 AGC\卸载 Apollo 11 AGC.lnk"
  RMDir "$SMPROGRAMS\Apollo 11 AGC"
  Delete "$DESKTOP\Apollo 11 AGC.lnk"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Apollo11AGC"
  DeleteRegKey HKLM "Software\Apollo11AGC"
SectionEnd
