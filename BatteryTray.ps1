
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Runtime.InteropServices

[System.Windows.Forms.Application]::EnableVisualStyles()

# ==================================================
# KONFIGURASI WIDGET BATERAI
# ==================================================

$script:RefreshInterval = 120000

$script:GrayColor = [System.Drawing.Color]::FromArgb(210, 100, 100, 100)

$script:NormalColor = [System.Drawing.Color]::FromArgb(230, 70, 180, 255)
$script:ChargingColor = [System.Drawing.Color]::FromArgb(230, 70, 220, 120)
$script:LowBatteryColor = [System.Drawing.Color]::FromArgb(230, 255, 65, 65)

$script:WidgetWidth = 85
$script:WidgetHeight = 75

$script:BatteryWidth = 20
$script:BatteryHeight = 48
$script:BatteryX = 8
$script:BatteryY = 15

$script:TerminalWidth = 10
$script:TerminalHeight = 4
$script:LineThickness = 1.2

$script:FontName = "Segoe UI"
$script:FontSize = 14
$script:FontBold = $true

$script:TextX = 35
$script:TextY = 28
$script:TextWidth = 48
$script:TextHeight = 24

$script:RightMargin = 12
$script:BottomMargin = 10

# ==================================================
# WINDOWS API UNTUK TRANSPARANSI PER PIKSEL
# ==================================================

if (-not ([System.Management.Automation.PSTypeName]'BatteryLayeredNative').Type) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class BatteryLayeredNative {
    [StructLayout(LayoutKind.Sequential)]
    public struct POINT {
        public int X;
        public int Y;
        public POINT(int x, int y) { X = x; Y = y; }
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct SIZE {
        public int CX;
        public int CY;
        public SIZE(int cx, int cy) { CX = cx; CY = cy; }
    }

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct BLENDFUNCTION {
        public byte BlendOp;
        public byte BlendFlags;
        public byte SourceConstantAlpha;
        public byte AlphaFormat;
    }

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool UpdateLayeredWindow(
        IntPtr hwnd, IntPtr hdcDst, ref POINT pptDst,
        ref SIZE psize, IntPtr hdcSrc, ref POINT pptSrc,
        int crKey, ref BLENDFUNCTION pblend, int dwFlags);

    [DllImport("user32.dll")]
    public static extern IntPtr GetDC(IntPtr hwnd);

    [DllImport("user32.dll")]
    public static extern int ReleaseDC(IntPtr hwnd, IntPtr hdc);

    [DllImport("gdi32.dll")]
    public static extern IntPtr CreateCompatibleDC(IntPtr hdc);

    [DllImport("gdi32.dll")]
    public static extern bool DeleteDC(IntPtr hdc);

    [DllImport("gdi32.dll")]
    public static extern IntPtr SelectObject(IntPtr hdc, IntPtr hObject);

    [DllImport("gdi32.dll")]
    public static extern bool DeleteObject(IntPtr hObject);

    [DllImport("user32.dll", EntryPoint="GetWindowLongW")]
    public static extern int GetWindowLong(IntPtr hwnd, int index);

    [DllImport("user32.dll", EntryPoint="SetWindowLongW")]
    public static extern int SetWindowLong(IntPtr hwnd, int index, int value);

    public const int GWL_EXSTYLE = -20;
    public const int WS_EX_LAYERED = 0x00080000;
    public const int ULW_ALPHA = 2;
    public const byte AC_SRC_OVER = 0;
    public const byte AC_SRC_ALPHA = 1;
}
"@
}

# ==================================================
# STATUS AWAL
# ==================================================

$script:BatteryLevel = 100
$script:Charging = $false
$script:Dragging = $false
$script:DragOffset = [System.Drawing.Point]::Empty
$script:ClosingWidget = $false

# ==================================================
# FORM TANPA BORDER, TANPA MAGENTA
# ==================================================

$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.ShowInTaskbar = $false
$form.TopMost = $true
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
$form.Size = New-Object System.Drawing.Size(
    $script:WidgetWidth,
    $script:WidgetHeight
)
$form.BackColor = [System.Drawing.Color]::Black
$form.KeyPreview = $true

# Layered window diaktifkan setelah handle dibuat
$form.Add_Shown({
    $style = [BatteryLayeredNative]::GetWindowLong(
        $form.Handle,
        [BatteryLayeredNative]::GWL_EXSTYLE
    )

    [void][BatteryLayeredNative]::SetWindowLong(
        $form.Handle,
        [BatteryLayeredNative]::GWL_EXSTYLE,
        ($style -bor [BatteryLayeredNative]::WS_EX_LAYERED)
    )
})

# ==================================================
# POSISI WIDGET
# ==================================================

function Set-WidgetPosition {
    $area = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea

    $form.Location = New-Object System.Drawing.Point(
        ($area.Right - $form.Width - $script:RightMargin),
        ($area.Bottom - $form.Height - $script:BottomMargin)
    )
}

Set-WidgetPosition

# ==================================================
# LABEL PERSENTASE
# Dihitung dalam bitmap agar transparan per piksel
# ==================================================

# Tidak menggunakan Label Windows Forms.
# Teks digambar langsung pada bitmap bersama indikator.

# ==================================================
# MENGGAMBAR BITMAP TRANSPARAN
# ==================================================

function Update-BatteryDrawing {
    if (-not $form.IsHandleCreated -or $script:ClosingWidget) {
        return
    }

    $width = $script:WidgetWidth
    $height = $script:WidgetHeight

    $bitmap = New-Object System.Drawing.Bitmap(
        $width,
        $height,
        [System.Drawing.Imaging.PixelFormat]::Format32bppPArgb
    )

    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $graphics.Clear([System.Drawing.Color]::Transparent)

    $pen = New-Object System.Drawing.Pen(
        $script:GrayColor,
        $script:LineThickness
    )

    try {
        $segmentHeight = $script:BatteryHeight / 5.0

        if ($script:BatteryLevel -le 20) {
            $fillColor = $script:LowBatteryColor
        }
        elseif ($script:Charging) {
            $fillColor = $script:ChargingColor
        }
        else {
            $fillColor = $script:NormalColor
        }

        $brush = New-Object System.Drawing.SolidBrush($fillColor)

        try {
            $segments = [Math]::Min(
                5,
                [Math]::Max(
                    0,
                    [Math]::Ceiling($script:BatteryLevel / 20.0)
                )
            )

            # Isi baterai dari bawah ke atas.
            # Segmen saling menyentuh tanpa celah putih.
            for ($i = 0; $i -lt $segments; $i++) {
                $segmentBottom = $script:BatteryY +
                    $script:BatteryHeight -
                    ($i * $segmentHeight)

                $fillY = [int][Math]::Floor(
                    $segmentBottom - $segmentHeight
                )

                $fillBottom = [int][Math]::Ceiling($segmentBottom)

                $graphics.FillRectangle(
                    $brush,
                    ($script:BatteryX + 1),
                    $fillY,
                    ($script:BatteryWidth - 2),
                    ($fillBottom - $fillY)
                )
            }
        }
        finally {
            $brush.Dispose()
        }

        # Garis luar baterai
        $graphics.DrawRectangle(
            $pen,
            $script:BatteryX,
            $script:BatteryY,
            $script:BatteryWidth,
            $script:BatteryHeight
        )

        # Terminal baterai
        $terminalX = $script:BatteryX +
            [int](($script:BatteryWidth - $script:TerminalWidth) / 2)

        $terminalY = $script:BatteryY - $script:TerminalHeight

        $graphics.DrawRectangle(
            $pen,
            $terminalX,
            $terminalY,
            $script:TerminalWidth,
            $script:TerminalHeight
        )

        # Garis pemisah abu-abu
        for ($i = 1; $i -lt 5; $i++) {
            $y = $script:BatteryY + [int]($i * $segmentHeight)

            $graphics.DrawLine(
                $pen,
                $script:BatteryX,
                $y,
                ($script:BatteryX + $script:BatteryWidth),
                $y
            )
        }

        # Teks persentase
        $fontStyle = [System.Drawing.FontStyle]::Regular
        if ($script:FontBold) {
            $fontStyle = [System.Drawing.FontStyle]::Bold
        }

        $font = New-Object System.Drawing.Font(
            $script:FontName,
            $script:FontSize,
            $fontStyle
        )

        $textBrush = New-Object System.Drawing.SolidBrush(
            $script:GrayColor
        )

        try {
            $textFormat = New-Object System.Drawing.StringFormat
            $textFormat.LineAlignment = [System.Drawing.StringAlignment]::Center
            $textFormat.Alignment = [System.Drawing.StringAlignment]::Near

            $displayText = if ($null -eq $script:BatteryLevel) {
                "N/A"
            } else {
                "$($script:BatteryLevel)%"
            }

            $textRect = New-Object System.Drawing.RectangleF(
                $script:TextX,
                $script:TextY,
                $script:TextWidth,
                $script:TextHeight
            )

            $graphics.DrawString(
                $displayText,
                $font,
                $textBrush,
                $textRect,
                $textFormat
            )

            $textFormat.Dispose()
        }
        finally {
            $font.Dispose()
            $textBrush.Dispose()
        }
    }
    finally {
        $pen.Dispose()
        $graphics.Dispose()
    }

    # Kirim bitmap alpha ke Windows sebagai layered window
    $screenDC = [BatteryLayeredNative]::GetDC([IntPtr]::Zero)
    $memoryDC = [BatteryLayeredNative]::CreateCompatibleDC($screenDC)
    $hBitmap = $bitmap.GetHbitmap([System.Drawing.Color]::FromArgb(0))
    $oldObject = [BatteryLayeredNative]::SelectObject($memoryDC, $hBitmap)

    try {
        $destination = New-Object BatteryLayeredNative+POINT(
            $form.Left,
            $form.Top
        )

        $size = New-Object BatteryLayeredNative+SIZE(
            $width,
            $height
        )

        $source = New-Object BatteryLayeredNative+POINT(0, 0)

        $blend = New-Object BatteryLayeredNative+BLENDFUNCTION
        $blend.BlendOp = [BatteryLayeredNative]::AC_SRC_OVER
        $blend.BlendFlags = 0
        $blend.SourceConstantAlpha = 255
        $blend.AlphaFormat = [BatteryLayeredNative]::AC_SRC_ALPHA

        $result = [BatteryLayeredNative]::UpdateLayeredWindow(
            $form.Handle,
            $screenDC,
            [ref]$destination,
            [ref]$size,
            $memoryDC,
            [ref]$source,
            0,
            [ref]$blend,
            [BatteryLayeredNative]::ULW_ALPHA
        )

        if (-not $result) {
            throw "Gagal memperbarui tampilan transparan."
        }
    }
    finally {
        [void][BatteryLayeredNative]::SelectObject($memoryDC, $oldObject)
        [void][BatteryLayeredNative]::DeleteObject($hBitmap)
        [void][BatteryLayeredNative]::DeleteDC($memoryDC)
        [void][BatteryLayeredNative]::ReleaseDC([IntPtr]::Zero, $screenDC)
        $bitmap.Dispose()
    }
}

# ==================================================
# MEMBACA STATUS BATERAI
# ==================================================

function Update-BatteryWidget {
    try {
        $battery = Get-CimInstance Win32_Battery -ErrorAction Stop |
            Select-Object -First 1

        if ($null -eq $battery) {
            $script:BatteryLevel = $null
            Update-BatteryDrawing
            return
        }

        $script:BatteryLevel = [Math]::Max(
            0,
            [Math]::Min(
                100,
                [int]$battery.EstimatedChargeRemaining
            )
        )

        $script:Charging = (
            $battery.BatteryStatus -in 2, 6, 7, 8, 9
        )
    }
    catch {
        $script:BatteryLevel = $null
    }

    Update-BatteryDrawing
}

# ==================================================
# TIMER PEMBARUAN SETIAP 2 MENIT
# ==================================================

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = $script:RefreshInterval

$timer.Add_Tick({
    Update-BatteryWidget
})

# ==================================================
# DRAG WIDGET DENGAN MOUSE
# ==================================================

$form.Add_MouseDown({
    if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $script:Dragging = $true
        $cursorPosition = [System.Windows.Forms.Cursor]::Position

        $script:DragOffset = New-Object System.Drawing.Point(
            ($cursorPosition.X - $form.Left),
            ($cursorPosition.Y - $form.Top)
        )
    }
})

$form.Add_MouseMove({
    if ($script:Dragging) {
        $cursorPosition = [System.Windows.Forms.Cursor]::Position

        $form.Location = New-Object System.Drawing.Point(
            ($cursorPosition.X - $script:DragOffset.X),
            ($cursorPosition.Y - $script:DragOffset.Y)
        )

        Update-BatteryDrawing
    }
})

$form.Add_MouseUp({
    $script:Dragging = $false
})

# ==================================================
# KELUAR DENGAN ESCAPE
# ==================================================

$form.Add_KeyDown({
    if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
        $script:ClosingWidget = $true
        $timer.Stop()
        $timer.Dispose()
        $form.Close()
    }
})

# ==================================================
# MENU KLIK KANAN
# ==================================================

$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$exitItem = New-Object System.Windows.Forms.ToolStripMenuItem("Keluar")

$exitItem.Add_Click({
    $script:ClosingWidget = $true
    $timer.Stop()
    $timer.Dispose()
    $form.Close()
})

[void]$contextMenu.Items.Add($exitItem)
$form.ContextMenuStrip = $contextMenu

# ==================================================
# MENJALANKAN WIDGET
# ==================================================

$form.Add_Shown({
    Update-BatteryWidget
    $timer.Start()
})

[void]$form.ShowDialog()
