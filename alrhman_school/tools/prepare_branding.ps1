param([Parameter(Mandatory = $true)][string]$SourceImage)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$appRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$source = [System.Drawing.Image]::FromFile((Resolve-Path -LiteralPath $SourceImage))
function Save-Icon([string]$relativePath, [int]$size) {
    $target = Join-Path $appRoot $relativePath
    New-Item -ItemType Directory -Path (Split-Path $target) -Force | Out-Null
    $bitmap = [System.Drawing.Bitmap]::new($size, $size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.DrawImage($source, 0, 0, $size, $size)
        $bitmap.Save($target, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally { $graphics.Dispose(); $bitmap.Dispose() }
}
try {
    New-Item -ItemType Directory -Path (Join-Path $appRoot 'branding') -Force | Out-Null
    Copy-Item -LiteralPath $SourceImage -Destination (Join-Path $appRoot 'branding/school_logo_original.png') -Force
    Save-Icon 'assets/images/school_logo.png' 512
    $densities = @{ 'mdpi' = 48; 'hdpi' = 72; 'xhdpi' = 96; 'xxhdpi' = 144; 'xxxhdpi' = 192 }
    foreach ($density in $densities.Keys) {
        Save-Icon "android/app/src/main/res/mipmap-$density/ic_launcher.png" $densities[$density]
        Save-Icon "android/app/src/main/res/drawable-$density/school_logo.png" ([int]($densities[$density] * 112 / 48))
    }
    $iosIcons = Get-Content -Raw (Join-Path $appRoot 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json') | ConvertFrom-Json
    foreach ($icon in $iosIcons.images) {
        $points = [double]($icon.size -split 'x')[0]
        $scale = [double]($icon.scale -replace 'x', '')
        Save-Icon "ios/Runner/Assets.xcassets/AppIcon.appiconset/$($icon.filename)" ([int]($points * $scale))
    }
    Save-Icon 'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png' 112
    Save-Icon 'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png' 224
    Save-Icon 'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png' 336
    Save-Icon 'web/favicon.png' 32
    foreach ($size in @(192, 512)) {
        Save-Icon "web/icons/Icon-$size.png" $size
        Save-Icon "web/icons/Icon-maskable-$size.png" $size
    }
    Write-Output 'Prepared school logo and platform icons.'
} finally { $source.Dispose() }
