# ============================================================
#  NVIDIA 颜色设置核心脚本（基于 NVAPI，不需要老版控制面板）
#  支持：数字振动(vibrance)、色调(hue)、灰度(gamma)
#
#  用法：
#    nvidia-color.ps1 -Action info
#    nvidia-color.ps1 -Action toggle -Type vibrance -On 100 -Off 50
#    nvidia-color.ps1 -Action toggle -Type hue -On 15 -Off 0
#    nvidia-color.ps1 -Action toggle -Type gamma -On 1.2 -Off 1.0
#    nvidia-color.ps1 -Action reset
# ============================================================

param(
    [ValidateSet('info', 'toggle', 'reset')]
    [string]$Action = 'info',
    [ValidateSet('vibrance', 'hue', 'gamma', 'all')]
    [string]$Type = 'all',
    [double]$On = 0,
    [double]$Off = 0
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms

$csCode = @'
using System;
using System.Runtime.InteropServices;

public static class NvColor
{
    // NVAPI 函数编号（来源：nvapi.h / 开源项目 NvAPIWrapper、nvidiot）
    const uint NVAPI_INITIALIZE    = 0x0150E828;
    const uint NVAPI_ENUM_DISPLAY  = 0x9ABDD40D;
    const uint NVAPI_GET_DVC_INFO  = 0x4085DE45;
    const uint NVAPI_SET_DVC_LEVEL = 0x172409B4;
    const uint NVAPI_GET_HUE_INFO  = 0x95B64341;
    const uint NVAPI_SET_HUE_ANGLE = 0x0F5A0F22C;

    [StructLayout(LayoutKind.Sequential)]
    public struct NvDvcInfo
    {
        public uint Version;
        public int CurrentLevel;
        public int MinLevel;
        public int MaxLevel;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct NvHueInfo
    {
        public uint Version;
        public int CurrentAngle;
        public int DefaultAngle;
    }

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    delegate int FNvApiInitialize();
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    delegate int FNvApiEnumDisplay(int index, out IntPtr handle);
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    delegate int FNvApiGetDvcInfo(IntPtr handle, uint outputId, ref NvDvcInfo info);
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    delegate int FNvApiSetDvcLevel(IntPtr handle, uint outputId, int level);
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    delegate int FNvApiGetHueInfo(IntPtr handle, uint outputId, ref NvHueInfo info);
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    delegate int FNvApiSetHueAngle(IntPtr handle, uint outputId, int angle);

    [DllImport("nvapi64.dll", CallingConvention = CallingConvention.Cdecl)]
    static extern IntPtr nvapi_QueryInterface(uint functionId);

    static FNvApiInitialize _init;
    static FNvApiEnumDisplay _enumDisplay;
    static FNvApiGetDvcInfo _getDvc;
    static FNvApiSetDvcLevel _setDvc;
    static FNvApiGetHueInfo _getHue;
    static FNvApiSetHueAngle _setHue;
    static IntPtr _display;
    static bool _ready;

    static T GetProc<T>(uint id) where T : class
    {
        IntPtr p = nvapi_QueryInterface(id);
        if (p == IntPtr.Zero)
            throw new Exception("NVAPI function unavailable: 0x" + id.ToString("X8"));
        return Marshal.GetDelegateForFunctionPointer(p, typeof(T)) as T;
    }

    static void EnsureInit()
    {
        if (_ready) return;
        _init = GetProc<FNvApiInitialize>(NVAPI_INITIALIZE);
        int s = _init();
        if (s != 0) throw new Exception("NvAPI_Initialize failed, status " + s);
        _enumDisplay = GetProc<FNvApiEnumDisplay>(NVAPI_ENUM_DISPLAY);
        _getDvc = GetProc<FNvApiGetDvcInfo>(NVAPI_GET_DVC_INFO);
        _setDvc = GetProc<FNvApiSetDvcLevel>(NVAPI_SET_DVC_LEVEL);
        _getHue = GetProc<FNvApiGetHueInfo>(NVAPI_GET_HUE_INFO);
        _setHue = GetProc<FNvApiSetHueAngle>(NVAPI_SET_HUE_ANGLE);
        _ready = true;
    }

    static IntPtr DisplayHandle()
    {
        EnsureInit();
        if (_display == IntPtr.Zero)
        {
            IntPtr h;
            int s = _enumDisplay(0, out h);
            if (s != 0 || h == IntPtr.Zero)
                throw new Exception("No NVIDIA display handle, status " + s);
            _display = h;
        }
        return _display;
    }

    static uint MakeVersion(Type t, int version)
    {
        return (uint)(Marshal.SizeOf(t) | (version << 16));
    }

    // ---------------- 数字振动 ----------------
    static NvDvcInfo DvcInfo()
    {
        NvDvcInfo info = new NvDvcInfo();
        info.Version = MakeVersion(typeof(NvDvcInfo), 1);
        int s = _getDvc(DisplayHandle(), 0, ref info);
        if (s != 0) throw new Exception("Read DVC failed, status " + s);
        return info;
    }

    public static int VibrancePercent()
    {
        NvDvcInfo info = DvcInfo();
        return LevelToPercent(info.CurrentLevel, info);
    }

    public static void SetVibrancePercent(int percent)
    {
        if (percent < 0) percent = 0;
        if (percent > 100) percent = 100;
        NvDvcInfo info = DvcInfo();
        int raw = PercentToLevel(percent, info);
        int s = _setDvc(DisplayHandle(), 0, raw);
        if (s != 0) throw new Exception("Set DVC failed, status " + s);
    }

    static int LevelToPercent(int level, NvDvcInfo info)
    {
        if (level >= 0 && info.MaxLevel > 0)
            return 50 + (int)Math.Round(level * 50.0 / info.MaxLevel);
        if (level < 0 && info.MinLevel < 0)
            return 50 - (int)Math.Round(level * 50.0 / info.MinLevel);
        return 50;
    }

    static int PercentToLevel(int percent, NvDvcInfo info)
    {
        if (percent >= 50)
            return (int)Math.Round((percent - 50) * info.MaxLevel / 50.0);
        if (info.MinLevel < 0)
            return (int)Math.Round((50 - percent) * info.MinLevel / 50.0);
        return 0;
    }

    // ---------------- 色调 ----------------
    public static int HueAngle()
    {
        NvHueInfo info = new NvHueInfo();
        info.Version = MakeVersion(typeof(NvHueInfo), 1);
        int s = _getHue(DisplayHandle(), 0, ref info);
        if (s != 0) throw new Exception("Read HUE failed, status " + s);
        return info.CurrentAngle;
    }

    public static void SetHueAngle(int angle)
    {
        angle = angle % 360;
        if (angle < 0) angle += 360;
        int s = _setHue(DisplayHandle(), 0, angle);
        if (s != 0) throw new Exception("Set HUE failed, status " + s);
    }

    // ---------------- 灰度（Win32 灰度曲线） ----------------
    [DllImport("user32.dll")]
    static extern IntPtr GetDC(IntPtr hWnd);
    [DllImport("user32.dll")]
    static extern int ReleaseDC(IntPtr hWnd, IntPtr hDC);
    [DllImport("gdi32.dll")]
    static extern bool SetDeviceGammaRamp(IntPtr hDC, ushort[] ramp);
    [DllImport("gdi32.dll")]
    static extern bool GetDeviceGammaRamp(IntPtr hDC, [Out] ushort[] ramp);

    static ushort[] BuildGammaRamp(double gamma)
    {
        ushort[] ramp = new ushort[256 * 3];
        double inv = 1.0 / gamma;
        for (int i = 0; i < 256; i++)
        {
            double x = i / 255.0;
            double v = Math.Pow(x, inv) * 65535.0;
            if (v < 0) v = 0;
            if (v > 65535) v = 65535;
            ushort s = (ushort)Math.Round(v);
            ramp[i] = s;
            ramp[256 + i] = s;
            ramp[512 + i] = s;
        }
        return ramp;
    }

    static ushort[] CurrentRamp()
    {
        IntPtr dc = GetDC(IntPtr.Zero);
        try
        {
            ushort[] ramp = new ushort[256 * 3];
            if (!GetDeviceGammaRamp(dc, ramp))
                throw new Exception("Read gamma ramp failed");
            return ramp;
        }
        finally
        {
            ReleaseDC(IntPtr.Zero, dc);
        }
    }

    public static bool GammaIsDefault()
    {
        ushort[] cur = CurrentRamp();
        ushort[] idn = BuildGammaRamp(1.0);
        for (int i = 0; i < cur.Length; i++)
        {
            if (Math.Abs(cur[i] - idn[i]) > 300) return false;
        }
        return true;
    }

    public static void SetGamma(double gamma)
    {
        if (gamma < 0.3) gamma = 0.3;
        if (gamma > 3.0) gamma = 3.0;
        ushort[] ramp = BuildGammaRamp(gamma);
        IntPtr dc = GetDC(IntPtr.Zero);
        try
        {
            if (!SetDeviceGammaRamp(dc, ramp))
                throw new Exception("Set gamma ramp failed");
        }
        finally
        {
            ReleaseDC(IntPtr.Zero, dc);
        }
    }
}

'@

function Show-Msg($text, $title, $icon) {
    [System.Windows.Forms.MessageBox]::Show($text, $title, [System.Windows.Forms.MessageBoxButtons]::OK, $icon) | Out-Null
}

try {
    Add-Type -TypeDefinition $csCode -Language CSharp
} catch {
    Show-Msg "加载 NVAPI 代码失败：$($_.Exception.Message)" '错误' 'Error'
    exit 1
}

try {
    switch ($Action) {
        'info' {
            $parts = @()
            try { $parts += "数字振动：$([NvColor]::VibrancePercent()) %" } catch { $parts += '数字振动：不可用' }
            try { $parts += "色调：$([NvColor]::HueAngle()) °" } catch { $parts += '色调：不可用' }
            try {
                if ([NvColor]::GammaIsDefault()) { $parts += '灰度：1.0（默认）' }
                else { $parts += '灰度：非默认' }
            } catch { $parts += '灰度：不可用' }
            Show-Msg ("当前颜色设置：`n`n" + ($parts -join "`n")) 'NVIDIA 颜色设置' 'Information'
        }
        'toggle' {
            switch ($Type) {
                'vibrance' {
                    $cur = [NvColor]::VibrancePercent()
                    $target = if ([math]::Abs($cur - $On) -le 2) { $Off } else { $On }
                    [NvColor]::SetVibrancePercent([int]$target)
                    if ($target -eq $Off) {
                        Show-Msg "数字振动已恢复默认：$Off %`n`n（再点一次可切到 $On %）" '数字振动' 'Information'
                    } else {
                        Show-Msg "数字振动已开启：$target %`n`n（再点一次可恢复默认 $Off %）" '数字振动' 'Information'
                    }
                }
                'hue' {
                    $cur = [NvColor]::HueAngle()
                    $dOn  = [math]::Abs((($cur - $On) % 360 + 540) % 360 - 180)
                    $dOff = [math]::Abs((($cur - $Off) % 360 + 540) % 360 - 180)
                    $target = if ($dOn -le 2) { $Off } elseif ($dOff -le 2) { $On } else { $On }
                    [NvColor]::SetHueAngle([int]$target)
                    if ($target -eq $Off) {
                        Show-Msg "色调已恢复默认：$Off °`n`n（再点一次可切到 $On °）" '色调' 'Information'
                    } else {
                        Show-Msg "色调已开启：$target °`n`n（再点一次可恢复默认 $Off °）" '色调' 'Information'
                    }
                }
                'gamma' {
                    $isDefault = [NvColor]::GammaIsDefault()
                    $target = if ($isDefault) { $On } else { $Off }
                    [NvColor]::SetGamma($target)
                    if ($isDefault) {
                        Show-Msg "灰度已开启：$target`n`n（再点一次可恢复默认 $Off）" '灰度' 'Information'
                    } else {
                        Show-Msg "灰度已恢复默认：$Off`n`n（再点一次可切到 $On）" '灰度' 'Information'
                    }
                }
                default {
                    Show-Msg "不支持的切换类型：$Type" '错误' 'Error'
                }
            }
        }
        'reset' {
            $errs = @()
            $tasks = @(
                @{ Name = '数字振动'; Run = { [NvColor]::SetVibrancePercent(50) } },
                @{ Name = '色调';     Run = { [NvColor]::SetHueAngle(0) } },
                @{ Name = '灰度';     Run = { [NvColor]::SetGamma(1.0) } }
            )
            foreach ($t in $tasks) {
                try { & $t.Run } catch { $errs += "$($t.Name)：$($_.Exception.Message)" }
            }
            if ($errs.Count -eq 0) {
                Show-Msg '颜色设置已恢复默认（数字振动 50%、色调 0°、灰度 1.0）' '完成' 'Information'
            } else {
                Show-Msg ("部分恢复成功，以下项目失败：`n`n" + ($errs -join "`n")) '完成（部分失败）' 'Warning'
            }
        }
        default {
            Show-Msg "不支持的操作：$Action" '错误' 'Error'
        }
    }
} catch {
    Show-Msg "操作失败：$($_.Exception.Message)`n`n（如果提示某个功能不可用，说明这台 GPU/驱动不支持该接口）" '错误' 'Error'
    exit 1
}
