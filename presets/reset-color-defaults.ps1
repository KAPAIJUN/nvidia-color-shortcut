# ============================================================
#  颜色相关设置全部恢复默认，并清零所有切换记忆
# ============================================================

$ErrorActionPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.Windows.Forms

$rundll = "$env:SystemRoot\System32\rundll32.exe"
$dll    = "$env:SystemRoot\System32\nvcpl.dll"
if (-not (Test-Path -LiteralPath $dll)) {
    $dll32 = "$env:SystemRoot\SysWOW64\nvcpl.dll"
    if (Test-Path -LiteralPath $dll32) {
        $dll    = $dll32
        $rundll = "$env:SystemRoot\SysWOW64\rundll32.exe"
    } else {
        [System.Windows.Forms.MessageBox]::Show("nvcpl.dll 不存在，老接口不支持。", '暂不支持', 'OK', 'Warning') | Out-Null
        exit 1
    }
}

& $rundll "$dll,dtcfg" 'setdefaults' '0' 'color'

# 清零切换记忆
foreach ($s in @('vibrance-100.state','vibrance-65.state','gamma-1.2.state')) {
    Remove-Item -LiteralPath (Join-Path $PSScriptRoot $s) -Force -ErrorAction SilentlyContinue
}

[System.Windows.Forms.MessageBox]::Show("颜色相关设置已恢复默认，切换记忆已清零。", '完成', 'OK', 'Information') | Out-Null
