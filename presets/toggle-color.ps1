# ============================================================
#  NVIDIA 颜色预设 · 来回切换（开/关）
#  双击一次 = 开启预设，再双击一次 = 恢复默认，如此循环。
#
#  说明：老接口 nvcpl.dll 无法读取当前值，
#        所以脚本用一个 .state 文件记住“现在是开还是关”。
# ============================================================

param([string]$Name)

$ErrorActionPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.Windows.Forms

$presets = @{
    'vibrance-100' = @{
        Args     = 'setdvc all 100'
        OffArgs  = 'setdvc all 50'
        OnLabel  = '数字振动 100（鲜艳）'
        OffLabel = '数字振动 50（默认）'
    }
    'vibrance-65' = @{
        Args     = 'setdvc all 65'
        OffArgs  = 'setdvc all 50'
        OnLabel  = '数字振动 65'
        OffLabel = '数字振动 50（默认）'
    }
    'gamma-1.2' = @{
        Args     = 'setgamma 0 all 1.2'
        OffArgs  = 'setgamma 0 all 1.0'
        OnLabel  = '灰度 1.2'
        OffLabel = '灰度 1.0（默认）'
    }
}

function Show-Msg($text, $title, $icon) {
    [System.Windows.Forms.MessageBox]::Show($text, $title, [System.Windows.Forms.MessageBoxButtons]::OK, $icon) | Out-Null
}

if (-not $presets.ContainsKey($Name)) {
    Show-Msg "未知预设：$Name" '错误' 'Error'
    exit 1
}

# ---- 找 nvcpl.dll（老接口），找不到就提示 ----
$rundll = "$env:SystemRoot\System32\rundll32.exe"
$dll    = "$env:SystemRoot\System32\nvcpl.dll"
if (-not (Test-Path -LiteralPath $dll)) {
    $dll32 = "$env:SystemRoot\SysWOW64\nvcpl.dll"
    if (Test-Path -LiteralPath $dll32) {
        $dll    = $dll32
        $rundll = "$env:SystemRoot\SysWOW64\rundll32.exe"
    } else {
        Show-Msg "这台驱动的 nvcpl.dll 不存在，老接口不支持一键切换。`n请用 NVIDIA 控制面板手动调整。`n`n（想要更可靠的切换，可试试开源 NVCP_Toggle）" '暂不支持' 'Warning'
        exit 1
    }
}

$p  = $presets[$Name]
$stateFile = Join-Path $PSScriptRoot "$Name.state"

$state = 'off'
if (Test-Path -LiteralPath $stateFile) {
    $state = ((Get-Content -Raw -LiteralPath $stateFile) -join '').Trim()
}

try {
    if ($state -eq 'on') {
        & $rundll "$dll,dtcfg" $p.OffArgs.Split(' ')
        Set-Content -LiteralPath $stateFile -Value 'off' -NoNewline
        Show-Msg "已恢复默认：$($p.OffLabel)`n`n再点一次即可重新开启。" 'NVIDIA 颜色预设' 'Information'
    } else {
        & $rundll "$dll,dtcfg" $p.Args.Split(' ')
        Set-Content -LiteralPath $stateFile -Value 'on' -NoNewline
        Show-Msg "已开启：$($p.OnLabel)`n`n再点一次即可恢复默认。" 'NVIDIA 颜色预设' 'Information'
    }
} catch {
    Show-Msg "执行失败：$($_.Exception.Message)" '错误' 'Error'
    exit 1
}
