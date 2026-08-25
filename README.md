# NVIDIA 颜色设置快捷方式

> Windows 上一键直达 NVIDIA 控制面板「调整桌面颜色设置」页（色调 / 灰度 / 数字振动），
> 并附带数字振动、灰度的一键「来回切换」预设脚本。

## ✨ 功能

- **一键直达**：双击快捷方式，直接打开 NVIDIA 控制面板的「调整桌面颜色设置」页，
  不用每次右键桌面 → NVIDIA 控制面板 → 显示 → 调整桌面颜色设置。
- **来回切换预设**：数字振动 100 / 65、灰度 1.2 等，双击一次开启、再双击恢复默认。
- 首次运行只需手动导航一次，之后全部一键直达。

## 📥 下载

点右上角绿色 **Code → Download ZIP**，或直接下载：
<https://github.com/KAPAIJUN/nvidia-color-shortcut/archive/refs/heads/main.zip>

解压后把**整个文件夹**放到 Windows 电脑（如 `D:\NVIDIA颜色设置\`），文件夹里的文件别删。

## 🚀 使用

### 1. 一键打开颜色设置页

1. 双击 `open-nvidia-color.bat`（**仅第一次**运行）：
   - 自动打开 NVIDIA 控制面板；
   - 按弹窗提示手动点开「显示 → 调整桌面颜色设置」页，点「确定」，脚本记住这一页；
   - 询问是否在桌面创建快捷方式，选「是」。
2. 以后双击桌面上的「NVIDIA 颜色设置」，直接打开那一页。

> **原理**：NVIDIA 控制面板每次启动会打开它“上次停留的页面”
> （注册表 `HKCU\Software\NVIDIA Corporation\NVControlPanel2\Client\LastPage`），
> 脚本启动前把目标页写回注册表，实现一键直达。

### 2. 预设来回切换（可选）

`presets/` 里的脚本是「开/关」来回切换模式，每次双击会弹窗提示当前状态：

| 脚本 | 行为 |
|---|---|
| `toggle-vibrance-100.bat` | 数字振动 100（鲜艳）↔ 50（默认） |
| `toggle-vibrance-65.bat` | 数字振动 65 ↔ 50（默认） |
| `toggle-gamma-1.2.bat` | 灰度 1.2 ↔ 1.0（默认） |
| `reset-all-color-defaults.bat` | 全部恢复默认，并清零切换记忆 |

## ⚠️ 注意事项

- 预设基于老驱动接口 `rundll32 NvCpl.dll,dtcfg`；新版驱动可能不带 `nvcpl.dll`，
  此时会提示「暂不支持」，用官方界面调即可。
- 切换状态由脚本自己记忆（`.state` 文件）。如果在官方面板里手动改过值，
  先点一次 `reset-all-color-defaults.bat` 清零。
- 多显示器：脚本默认操作主显示器（编号 0），可编辑
  `presets/toggle-color.ps1` 里的 `setgamma` / `setdefaults`，把 `0` 改成 `1` 或 `2`。
- 需要更可靠（NVAPI、可读取当前值）的切换：试试开源 [NVCP_Toggle](https://github.com/mcgrizzz/NVCP_Toggle)。

## 💻 环境要求

- Windows 10 / 11
- NVIDIA 显卡 + 已安装 NVIDIA 驱动
- 无需安装任何软件（脚本用系统自带 PowerShell）

## 📄 许可

[MIT](./LICENSE)
