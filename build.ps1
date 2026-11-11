# Builds src/ into a single file "Armandala Game.html"
# Run: powershell -ExecutionPolicy Bypass -File build.ps1
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)
function Read-Text($p) { [IO.File]::ReadAllText((Join-Path $root $p), [Text.Encoding]::UTF8) }
function Font-B64($p) { [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $root $p))) }

$cyrRange = 'U+0301,U+0400-045F,U+0490-0491,U+04B0-04B1,U+2116'
$fonts = @"
@font-face{font-family:Nunito;font-weight:900;font-display:swap;src:url(data:font/woff2;base64,$(Font-B64 'src\vendor\nunito-lat-900.woff2')) format('woff2')}
@font-face{font-family:Nunito;font-weight:900;font-display:swap;unicode-range:$cyrRange;src:url(data:font/woff2;base64,$(Font-B64 'src\vendor\nunito-cyr-900.woff2')) format('woff2')}
@font-face{font-family:Nunito;font-weight:700;font-display:swap;unicode-range:$cyrRange;src:url(data:font/woff2;base64,$(Font-B64 'src\vendor\nunito-cyr-700.woff2')) format('woff2')}
"@

$scripts = New-Object Text.StringBuilder

# Logo badge: assets\logo-badge.jpg is resized and embedded into the game (window.AG_LOGO_BADGE)
$badgeJs = ''
$bp = Join-Path $root 'assets\logo-badge.jpg'
if (Test-Path -LiteralPath $bp) {
  Add-Type -AssemblyName System.Drawing
  $img = [Drawing.Image]::FromFile($bp)
  $bw = 640; $bh = [int]($img.Height * $bw / $img.Width)
  $bmp = New-Object Drawing.Bitmap($bw, $bh)
  $g = [Drawing.Graphics]::FromImage($bmp); $g.InterpolationMode = 'HighQualityBicubic'; $g.SmoothingMode = 'HighQuality'
  $g.DrawImage($img, 0, 0, $bw, $bh); $g.Dispose(); $img.Dispose()
  $codec = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
  $ep = New-Object Drawing.Imaging.EncoderParameters(1)
  $ep.Param[0] = New-Object Drawing.Imaging.EncoderParameter([Drawing.Imaging.Encoder]::Quality, [long]92)
  $ms = New-Object IO.MemoryStream; $bmp.Save($ms, $codec, $ep); $bmp.Dispose()
  $badgeJs = "window.AG_LOGO_BADGE='data:image/jpeg;base64," + [Convert]::ToBase64String($ms.ToArray()) + "';"
  Write-Output ("Badge embedded: {0} x {1}, {2:N0} KB" -f $bw, $bh, ($ms.Length / 1KB))
} else { Write-Output 'No assets\logo-badge.jpg found - using the drawn logo.' }
[void]$scripts.Append("<script>`n$badgeJs`n</script>`n")

foreach ($f in 'src\vendor\three.min.js','src\js\core.js','src\js\art.js','src\js\characters.js','src\js\game.js','src\js\net.js','src\js\ui.js') {
  $code = (Read-Text $f).Replace('</script', '<\/script')
  [void]$scripts.Append("<script>`n").Append($code).Append("`n</script>`n")
}

$html = Read-Text 'src\index.template.html'
$html = $html.Replace('/*__FONTS__*/', $fonts).Replace('/*__CSS__*/', ((Read-Text 'src\style.css') + (Read-Text 'src\online.css'))).Replace('<!--__SCRIPTS__-->', $scripts.ToString())
$out = Join-Path $root 'Armandala Game.html'
[IO.File]::WriteAllText($out, $html, $utf8)
Write-Output ("Built: {0} ({1:N1} MB)" -f $out, ((Get-Item -LiteralPath $out).Length / 1MB))
