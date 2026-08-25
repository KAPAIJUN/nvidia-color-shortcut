# ============================================================
#  NVIDIA 颜色设置一键直达
#  打开 NVIDIA 控制面板的「调整桌面颜色设置」页面（色调/灰度/数字振动那页）
#
#  原理：NVIDIA 控制面板每次启动都会打开它“上次停留的页面”，
#        该记录保存在注册表 LastPage 里。
#        本脚本在启动前把目标页面写回注册表，从而实现一键直达。
# ============================================================

$ErrorActionPreference = 'SilentlyContinue'

Add-Type -AssemblyName System.Windows.Forms

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$saveFile  = Join-Path $scriptDir 'nvcolor-lastpage.json'
$regPath   = 'HKCU:\Software\NVIDIA Corporation\NVControlPanel2\Client'
$regName   = 'LastPage'

function Show-Msg($text, $title, $icon) {
    [System.Windows.Forms.MessageBox]::Show($text, $title, [System.Windows.Forms.MessageBoxButtons]::OK, $icon) | Out-Null
}

function Find-NvCpl {
    # 1) 经典（非 DCH）驱动路径
    $paths = @(
        "$env:ProgramFiles\NVIDIA Corporation\Control Panel Client\nvcplui.exe",
        "${env:ProgramFiles(x86)}\NVIDIA Corporation\Control Panel Client\nvcplui.exe"
    )
    foreach ($p in $paths) {
        if (Test-Path -LiteralPath $p) { return @{ Type = 'exe'; Path = $p } }
    }

    # 2) DCH / 微软商店版（通过应用 AppID 启动）
    $app = Get-StartApps | Where-Object { $_.Name -match 'NVIDIA Control Panel' } | Select-Object -First 1
    if ($app) { return @{ Type = 'appx'; Path = $app.AppID } }

    # 3) 最后尝试：直接在 WindowsApps 目录里找
    $found = Get-ChildItem "$env:ProgramFiles\WindowsApps" -Filter 'nvcplui.exe' -Recurse -ErrorAction SilentlyContinue |
             Where-Object { $_.FullName -match 'NVIDIACorp' } | Select-Object -First 1
    if ($found) { return @{ Type = 'exe'; Path = $found.FullName } }

    return $null
}

function Start-NvCpl($nv) {
    if ($nv.Type -eq 'appx') {
        Start-Process 'explorer.exe' -ArgumentList "shell:AppsFolder\$($nv.Path)"
    } else {
        Start-Process -FilePath $nv.Path
    }
}

function New-DesktopShortcut($nv) {
    try {
        $desktop = [Environment]::GetFolderPath('Desktop')
        $lnk = Join-Path $desktop 'NVIDIA 颜色设置.lnk'
        $ws = New-Object -ComObject WScript.Shell
        $sc = $ws.CreateShortcut($lnk)
        $ps1 = Join-Path $scriptDir 'open-nvidia-color.ps1'
        $sc.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
        $sc.Arguments = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $ps1 + '"'
        $sc.WorkingDirectory = $scriptDir
        $sc.Description = '打开 NVIDIA 控制面板的「调整桌面颜色设置」页面'
        if ($nv.Type -eq 'exe' -and (Test-Path -LiteralPath $nv.Path)) {
            $sc.IconLocation = "$($nv.Path),0"
        }
        $sc.Save()
        return $true
    } catch {
        return $false
    }
}

try {
    # ---------- 1. 找到 NVIDIA 控制面板 ----------
    $nv = Find-NvCpl
    if (-not $nv) {
        Show-Msg "没有找到 NVIDIA 控制面板（nvcplui.exe）。`n`n请确认：`n1) 这台电脑装的是 NVIDIA 显卡驱动；`n2) 打开过一次「NVIDIA 控制面板」。`n`n然后重试。" '找不到 NVIDIA 控制面板' 'Warning'
        exit 1
    }

    # ---------- 2. 启动前：把已保存的目标页面写回注册表 ----------
    $saved = $null
    if (Test-Path -LiteralPath $saveFile) {
        try { $saved = Get-Content -Raw -LiteralPath $saveFile | ConvertFrom-Json } catch { $saved = $null }
    }
    if ($saved -and $saved.LastPage) {
        try {
            if ($saved.Type -eq 'DWord') {
                Set-ItemProperty -Path $regPath -Name $regName -Value ([int]$saved.LastPage) -Type DWord
            } else {
                Set-ItemProperty -Path $regPath -Name $regName -Value ([string]$saved.LastPage) -Type String
            }
        } catch { }
    }

    Start-NvCpl $nv

    # ---------- 3. 第一次运行：引导用户记住目标页面 ----------
    if (-not $saved) {
        Start-Sleep -Seconds 1
        $ans = [System.Windows.Forms.MessageBox]::Show(
            "这是第一次运行。`n`n请在弹出的 NVIDIA 控制面板里：`n左侧展开「显示」→ 点击「调整桌面颜色设置」`n打开那一页后，再点下面的「确定」。`n`n以后双击快捷方式就会直接打开那一页。",
            'NVIDIA 颜色设置 · 第一次使用',
            [System.Windows.Forms.MessageBoxButtons]::OKCancel,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        if ($ans -eq [System.Windows.Forms.DialogResult]::OK) {
            Start-Sleep -Seconds 1
            $prop = Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue
            if ($prop) {
                $val  = $prop.$regName
                $type = $prop.PSObject.Properties[$regName].TypeNameOfValue
                if ($null -ne $val) {
                    $isDword = $type -match 'DWord|Int32|UInt32'
                    @{ LastPage = $val; Type = $(if ($isDword) { 'DWord' } else { 'String' }) } |
                        ConvertTo-Json -Compress |
                        Set-Content -Encoding UTF8 -LiteralPath $saveFile

                    $mk = [System.Windows.Forms.MessageBox]::Show(
                        "已记住目标页面，下次双击即可直达。`n`n是否在桌面创建快捷方式「NVIDIA 颜色设置」？",
                        '设置完成',
                        [System.Windows.Forms.MessageBoxButtons]::YesNo,
                        [System.Windows.Forms.MessageBoxIcon]::Question
                    )
                    if ($mk -eq [System.Windows.Forms.DialogResult]::Yes) {
                        if (New-DesktopShortcut $nv) {
                            Show-Msg '已在桌面创建快捷方式「NVIDIA 颜色设置」。' '完成' 'Information'
                        } else {
                            Show-Msg '创建快捷方式失败，请手动创建：`n右键 open-nvidia-color.bat → 发送到 → 桌面快捷方式。' '提示' 'Warning'
                        }
                    }
                } else {
                    Show-Msg "没读到页面信息（可能驱动版本不同）。`n不影响使用：以后控制面板会默认打开你上次看的页面。" '提示' 'Information'
                }
            } else {
                Show-Msg "没找到注册表页面记录（可能驱动版本不同）。`n不影响使用：以后控制面板会默认打开你上次看的页面。" '提示' 'Information'
            }
        }
    }
} catch {
    Show-Msg "出错了：$($_.Exception.Message)" '错误' 'Error'
    exit 1
}
