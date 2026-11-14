# ينشئ مفتاح الرفع (upload key) لـ Google Play مرة واحدة فقط، ويكتب android/key.properties.
# المفتاح يُحفظ خارج المشروع. انسخه مع كلمة السر إلى مكان آمن: بدونه لا يمكن تحديث التطبيق.
# الرسائل بالإنجليزية لأن نافذة PowerShell 5.1 تعرض العربية مقطّعة ومعكوسة.
#   powershell -ExecutionPolicy Bypass -File tools\create_upload_key.ps1
param(
    [string]$KeystorePath = (Join-Path $HOME 'keys\alrahman-upload.jks'),
    [string]$Alias = 'upload',
    [string]$Organization = 'Al-Rahman Primary School'
)
$ErrorActionPreference = 'Stop'
$appRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$propsPath = Join-Path $appRoot 'android\key.properties'

if (Test-Path -LiteralPath $KeystorePath) { throw "Key already exists: $KeystorePath (do not create a second one)" }
if (Test-Path -LiteralPath $propsPath) { throw "File already exists: $propsPath" }
if (-not (Get-Command keytool -ErrorAction SilentlyContinue)) { throw 'keytool not found (it comes with Java/JDK)' }

function Read-Plain([string]$prompt) {
    $secure = Read-Host -AsSecureString $prompt
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}
$password = Read-Plain 'Key password (at least 8 characters)'
if ($password.Length -lt 8) { throw 'Password is too short' }
if ($password -ne (Read-Plain 'Repeat the password')) { throw 'Passwords do not match' }
if ($password -notmatch '^[\x21-\x5B\x5D-\x7E]+$') { throw 'Password: English letters, digits and symbols only, no spaces and no \' }

New-Item -ItemType Directory -Path (Split-Path $KeystorePath) -Force | Out-Null
& keytool -genkeypair -keystore $KeystorePath -storetype PKCS12 -alias $Alias `
    -keyalg RSA -keysize 2048 -validity 10000 `
    -dname "CN=$Organization, O=$Organization, C=IQ" `
    -storepass $password -keypass $password
if ($LASTEXITCODE -ne 0) { throw 'keytool failed' }

$storeFile = $KeystorePath -replace '\\', '/'
@(
    "storeFile=$storeFile",
    "storePassword=$password",
    "keyAlias=$Alias",
    "keyPassword=$password"
) | Set-Content -LiteralPath $propsPath -Encoding ascii

Write-Host ''
Write-Host "Created: $KeystorePath"
Write-Host "Written: $propsPath (not in git)"
Write-Host 'IMPORTANT: back up the .jks file and its password to a second safe place now.'
