# Play Console product icons (512x512, 32-bit PNG, no text) for the 4 IAP packs,
# composed from the game's own art in art_src/.
#   powershell -NoProfile -File tool/iap_icons.ps1   (run from the project root)
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'
$S = 512
$out = Join-Path (Get-Location) 'store/iap'
New-Item -ItemType Directory -Force $out | Out-Null

function New-Canvas {
  $b = New-Object System.Drawing.Bitmap $S, $S, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($b)
  $g.SmoothingMode = 'AntiAlias'; $g.InterpolationMode = 'HighQualityBicubic'; $g.PixelOffsetMode = 'HighQuality'
  # warm field-light background: radial cream -> soft gold
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $path.AddEllipse(-160, -170, $S + 320, $S + 340)
  $br = New-Object System.Drawing.Drawing2D.PathGradientBrush $path
  $br.CenterColor = [System.Drawing.Color]::FromArgb(255, 255, 249, 228)
  $br.SurroundColors = @([System.Drawing.Color]::FromArgb(255, 238, 200, 120))
  $g.FillRectangle($br, 0, 0, $S, $S)
  # soft ground shadow
  $sh = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(45, 120, 80, 20))
  $g.FillEllipse($sh, 86, 392, 340, 56)
  return @($b, $g)
}

# Draw art_src/<name>.png trimmed to its opaque box, fitted into (cx, bottom, maxW, maxH).
function Draw-Art($g, $name, $cx, $bottom, $maxW, $maxH) {
  $im = [System.Drawing.Bitmap]::FromFile((Resolve-Path "art_src/$name.png"))
  $minX = $im.Width; $minY = $im.Height; $maxX = 0; $maxY = 0
  for ($y = 0; $y -lt $im.Height; $y += 4) { for ($x = 0; $x -lt $im.Width; $x += 4) {
    if ($im.GetPixel($x, $y).A -gt 24) { if ($x -lt $minX) { $minX = $x }; if ($x -gt $maxX) { $maxX = $x }; if ($y -lt $minY) { $minY = $y }; if ($y -gt $maxY) { $maxY = $y } } } }
  $w = $maxX - $minX + 4; $h = $maxY - $minY + 4
  $k = [math]::Min($maxW / $w, $maxH / $h)
  $dw = $w * $k; $dh = $h * $k
  $g.DrawImage($im, (New-Object System.Drawing.RectangleF ($cx - $dw / 2), ($bottom - $dh), $dw, $dh), (New-Object System.Drawing.RectangleF $minX, $minY, $w, $h), 'Pixel')
  $im.Dispose()
}

function Save($pair, $name) { $pair[1].Dispose(); $pair[0].Save("$out/$name.png", [System.Drawing.Imaging.ImageFormat]::Png); $pair[0].Dispose(); "store/iap/$name.png" }

# 1. Gói khởi đầu: lantern arbor + lotus pot behind a gift basket
$c = New-Canvas
Draw-Art $c[1] 'den_long' 352 360 230 230
Draw-Art $c[1] 'chau_sen' 160 372 190 230
Draw-Art $c[1] 'gio_qua' 270 430 330 230
Save $c 'goi_khoi_dau'

# 2. Hầm chứa
$c = New-Canvas
Draw-Art $c[1] 'ham_chua' 256 430 430 400
Save $c 'ham_chua'

# 3. Thẻ Nhà Nông: rice sheaf with a basket of grain
$c = New-Canvas
Draw-Art $c[1] 'item_rom' 300 400 260 330
Draw-Art $c[1] 'item_thoc' 205 435 270 230
Save $c 'the_nha_nong'

# 4. Bỏ quảng cáo: a village loudspeaker, crossed out
$c = New-Canvas; $g = $c[1]
$g.TranslateTransform(236, 252); $g.RotateTransform(-14); $g.ScaleTransform(0.86, 0.86)
$horn = New-Object System.Drawing.Drawing2D.GraphicsPath
$horn.AddPolygon(@((New-Object System.Drawing.PointF -40, -38), (New-Object System.Drawing.PointF 120, -118), (New-Object System.Drawing.PointF 120, 118), (New-Object System.Drawing.PointF -40, 38)))
$hb = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.PointF 0, -120), (New-Object System.Drawing.PointF 0, 120), ([System.Drawing.Color]::FromArgb(255, 214, 222, 214)), ([System.Drawing.Color]::FromArgb(255, 120, 136, 128))
$g.FillPath($hb, $horn)
$g.DrawPath((New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 70, 80, 74)), 6), $horn)
$g.FillEllipse((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 60, 68, 64))), 96, -118, 48, 236)
$g.FillEllipse((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 150, 160, 152))), 104, -104, 32, 208)
$g.FillRectangle((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 92, 100, 96))), -110, -44, 76, 88)
$g.DrawRectangle((New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 60, 68, 64)), 6), -110, -44, 76, 88)
$g.ResetTransform()
# red prohibition ring
$rp = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 214, 48, 40)), 34
$g.DrawEllipse($rp, 76, 70, 360, 360)
$rp.StartCap = 'Flat'
$g.DrawLine($rp, 138, 132, 374, 368)
Save $c 'bo_quang_cao'
