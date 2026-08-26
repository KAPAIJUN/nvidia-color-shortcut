# ============================================================
#  打开 NVIDIA 颜色设置界面
#  1) 装了老版 NVIDIA 控制面板 -> 打开它（停在它上次的页面）
#  2) 否则打开新版 NVIDIA App，并提示进入颜色设置的路径
# ============================================================

$ErrorActionPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.Windows.Forms

function Show-Msg($text, $title, $icon) {
    [System.Windows.Forms.MessageBox]::Show($text, $title, [System.Windows.Forms.MessageBoxButtons]::OK, $icon) | Out-Null
}

# --- 1) 老版 NVIDIA 控制面板 ---
$cpl = @(
    "$env:ProgramFiles\NVIDIA Corporation\Control Panel Client\nvcplui.exe",
    "${env:ProgramFiles(x86)}\NVIDIA Corporation\Control Panel Client\nvcplui.exe"
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

if ($cpl) {
    Start-Process -FilePath $cpl
    Show-Msg '已打开 NVIDIA 控制面板（会停在它上次停留的页面）。' 'NVIDIA 颜色设置' 'Information'
    exit 0
}

# --- 2) 新版 NVIDIA App ---
$app = Get-StartApps | Where-Object { $_.Name -like '*NVIDIA*app*' } | Select-Object -First 1
if ($app) {
    Start-Process 'explorer.exe' -ArgumentList "shell:AppsFolder\$($app.AppID)"
    Show-Msg "已打开 NVIDIA App。`n`n请依次点击：`n设置 → 显示器 → 显示设置 → 颜色`n`n（英文界面：System → Displays → Display Settings → Color）" 'NVIDIA 颜色设置' 'Information'
    exit 0
}

# --- 兜底：在安装目录里找 exe ---
$appExe = Get-ChildItem "$env:ProgramFiles\NVIDIA Corporation" -Recurse -Filter '*.exe' -ErrorAction SilentlyContinue |
          Where-Object { $_.Name -like 'NVIDIA*app*.exe' } | Select-Object -First 1
if ($appExe) {
    Start-Process -FilePath $appExe.FullName
    Show-Msg "已打开 NVIDIA App。`n`n请依次点击：`n设置 → 显示器 → 显示设置 → 颜色" 'NVIDIA 颜色设置' 'Information'
    exit 0
}

Show-Msg "没有找到 NVIDIA App 或 NVIDIA 控制面板。`n`n请确认已安装：`n- 新版 NVIDIA App（NVIDIA 官网 / 微软商店）`n- 或到微软商店安装「NVIDIA Control Panel」" '找不到' 'Warning'
exit 1
