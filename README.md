# NVIDIA 颜色设置工具（新版 NVIDIA App 适用）

> 新版 NVIDIA 驱动不再自带老版「NVIDIA 控制面板」，颜色设置（色调 / 灰度 / 数字振动）
> 已整合进 **NVIDIA App**。本工具通过 **NVAPI 直接调用驱动**来读写颜色设置，
> **不需要老版控制面板**，只要装了 NVIDIA 驱动即可。

## ✨ 功能

- **一键来回切换**：数字振动 100/65、色调 15°、灰度 1.2 等，双击一次开启、再双击恢复默认，自动读取当前值判断状态，不需要状态文件。
- **查看当前值**：`info-color.bat` 显示当前数字振动 / 色调 / 灰度。
- **打开颜色设置界面**：`open-nvidia-color.bat` 打开 NVIDIA App（或老版控制面板）并提示进入路径。

## 📥 下载

点右上角绿色 **Code → Download ZIP**，或直接下载：
<https://github.com/KAPAIJUN/nvidia-color-shortcut/archive/refs/heads/main.zip>

解压后把**整个文件夹**放到 Windows 电脑（如 `D:\NVIDIA颜色设置\`），文件夹里的文件别删。

## 🚀 使用

### 1. 一键打开颜色设置界面

双击 `open-nvidia-color.bat` → 打开 NVIDIA App，按提示点击：
`设置 → 显示器 → 显示设置 → 颜色`
（英文界面：`System → Displays → Display Settings → Color`）

### 2. 预设来回切换（`presets/`）

| 脚本 | 行为 |
|---|---|
| `toggle-vibrance-100.bat` | 数字振动 100（鲜艳）↔ 50（默认） |
| `toggle-vibrance-65.bat` | 数字振动 65 ↔ 50（默认） |
| `toggle-hue-15.bat` | 色调 15° ↔ 0°（默认） |
| `toggle-gamma-1.2.bat` | 灰度 1.2 ↔ 1.0（默认） |
| `reset-all-color-defaults.bat` | 全部恢复默认 |

每次双击会弹窗提示当前状态（已开启 / 已恢复默认）。

### 3. 查看当前数值

双击 `info-color.bat`，弹出当前数字振动、色调、灰度。

## ⚙️ 工作原理

- **数字振动 / 色调**：通过 NVAPI（`nvapi64.dll`）的 `NvAPI_SetDVCLevel` / `NvAPI_SetHUEAngle` 直接读写，和官方界面一致。
- **灰度**：通过 Windows 灰度曲线（`SetDeviceGammaRamp`）实现，视觉生效，但不会显示在 NVIDIA App 的灰度滑块里。
- 切换逻辑是「读取当前值 → 反着切」，即使你在官方界面手动改过也能正确判断。

## ⚠️ 注意事项

- 需要 **64 位** Windows 10/11 + NVIDIA 驱动（脚本加载 64 位 `nvapi64.dll`）。
- 如果某个项目提示「不可用」，说明该 GPU/驱动不支持对应接口（例如部分 GPU 不支持 NVAPI 色调接口），其它项目不受影响。
- 自定义数值：编辑 `presets/` 里的 `.bat`，改 `-On` / `-Off` 后的数字（数字振动 0-100；色调 0-359；灰度建议 0.5-2.0）。
- 想要老版控制面板界面：微软商店仍可安装「NVIDIA Control Panel」，装完 `open-nvidia-color.bat` 会优先打开它。
- 更强大的预设切换工具（NVAPI、.NET）：[NVCP_Toggle](https://github.com/mcgrizzz/NVCP_Toggle)

## 💻 环境要求

- Windows 10 / 11（64 位）
- NVIDIA 显卡 + 已安装 NVIDIA 驱动（无需 NVIDIA App 或老版控制面板，只要有驱动即可）
- 无需安装任何软件（脚本用系统自带 PowerShell）

## 📄 许可

[MIT](./LICENSE)
