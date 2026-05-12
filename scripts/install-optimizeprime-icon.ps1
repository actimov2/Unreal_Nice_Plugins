# Resize LOGO.png to Unreal plugin icons (128 + 40) and place in Resources/
[CmdletBinding()]
param(
    [string] $Src = "Graphic\LOGO.png",
    [string] $PluginDir = "HostProject\Plugins\OptimizePrime"
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$resDir = Join-Path $PluginDir 'Resources'
New-Item -ItemType Directory -Path $resDir -Force | Out-Null

$srcImg = [System.Drawing.Image]::FromFile((Resolve-Path -LiteralPath $Src))
Write-Host "Source: $($srcImg.Width) x $($srcImg.Height) px"

function Save-Resized {
    param([System.Drawing.Image] $Image, [int] $Size, [string] $OutPath)
    $bmp = New-Object System.Drawing.Bitmap $Size, $Size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)

    # Fit-square: center the source into a Size x Size box, preserving aspect.
    $srcW = $Image.Width; $srcH = $Image.Height
    $scale = [Math]::Min($Size / $srcW, $Size / $srcH)
    $w = [int]($srcW * $scale); $h = [int]($srcH * $scale)
    $x = [int](($Size - $w) / 2); $y = [int](($Size - $h) / 2)
    $g.DrawImage($Image, $x, $y, $w, $h)

    $bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Write-Host "Wrote: $OutPath ($Size x $Size)"
}

Save-Resized -Image $srcImg -Size 128 -OutPath (Join-Path $resDir 'Icon128.png')
Save-Resized -Image $srcImg -Size 40  -OutPath (Join-Path $resDir 'Icon40.png')

$srcImg.Dispose()
Write-Host "Done."
