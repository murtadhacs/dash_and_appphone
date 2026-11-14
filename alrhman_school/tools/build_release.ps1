# يبني ملف AAB لـ Google Play على Production، موقّعاً بمفتاح الرفع، وينسخه إلى releases/<version>/.
# الرسائل بالإنجليزية لأن نافذة PowerShell 5.1 تعرض العربية مقطّعة ومعكوسة.
#   powershell -ExecutionPolicy Bypass -File tools\build_release.ps1
param([string]$ApiBaseUrl = 'https://alrahmanschool.up.railway.app')
$ErrorActionPreference = 'Stop'
$appRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$propsPath = Join-Path $appRoot 'android\key.properties'

if (-not (Test-Path -LiteralPath $propsPath)) {
    throw 'android/key.properties is missing. Run tools\create_upload_key.ps1 first (or restore it from your backup).'
}
$versionLine = Select-String -LiteralPath (Join-Path $appRoot 'pubspec.yaml') -Pattern '^version:\s*(\S+)' | Select-Object -First 1
if (-not $versionLine) { throw 'No version in pubspec.yaml' }
$version = $versionLine.Matches[0].Groups[1].Value
$versionName = ($version -split '\+')[0]

# تحذيرات flutter/keytool على stderr ليست أخطاء؛ النجاح يُحكم بـ $LASTEXITCODE فقط.
Push-Location $appRoot
$ErrorActionPreference = 'Continue'
try {
    & flutter build appbundle --release "--dart-define=API_BASE_URL=$ApiBaseUrl" 2>&1 | ForEach-Object { "$_" }
    $buildExit = $LASTEXITCODE
} finally { Pop-Location; $ErrorActionPreference = 'Stop' }
if ($buildExit -ne 0) { throw 'flutter build appbundle failed' }

$aab = Join-Path $appRoot 'build\app\outputs\bundle\release\app-release.aab'
$ErrorActionPreference = 'Continue'
$cert = (& keytool -printcert -jarfile $aab 2>&1 | ForEach-Object { "$_" }) -join "`n"
$ErrorActionPreference = 'Stop'
if ($cert -match 'Android Debug') { throw 'The bundle is signed with the debug key; Google Play will reject it' }

$outDir = Join-Path $appRoot "..\releases\$versionName"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null
$target = Join-Path $outDir "alrhman_school_parent_$versionName.aab"
Copy-Item -LiteralPath $aab -Destination $target -Force

Write-Host ''
Write-Host "Version: $version  Server: $ApiBaseUrl"
Write-Host "File: $([System.IO.Path]::GetFullPath($target))"
Write-Host "SHA256: $((Get-FileHash -Algorithm SHA256 -LiteralPath $target).Hash.ToLower())"
Write-Host ($cert -split "`n" | Select-String -Pattern 'Owner|SHA256:' | Out-String)
