# يبني نسخة الويب وينسخها إلى deploy/railway/site جاهزة للرفع.
#   powershell -File deploy/railway/prepare.ps1
$ErrorActionPreference = 'Stop'
$root = Resolve-Path "$PSScriptRoot/../.."
Push-Location $root
try {
    flutter build web --dart-define=API_BASE_URL= --no-wasm-dry-run
    $site = Join-Path $PSScriptRoot 'site'
    if (Test-Path $site) { Remove-Item $site -Recurse -Force }
    Copy-Item build/web $site -Recurse
    Write-Host "جاهز: deploy/railway/site"
} finally {
    Pop-Location
}
