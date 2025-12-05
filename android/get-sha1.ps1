# Script lấy SHA-1 fingerprint từ Release Keystore
# PowerShell script to get SHA-1 from Android release keystore

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Lấy SHA-1 Fingerprint" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Find keytool
$keytoolPath = $null

$javaPaths = @(
    "$env:JAVA_HOME\bin\keytool.exe",
    "C:\Program Files\Java\*\bin\keytool.exe",
    "C:\Program Files (x86)\Java\*\bin\keytool.exe",
    "$env:LOCALAPPDATA\Android\Sdk\jre\bin\keytool.exe",
    "C:\Android\jdk\*\bin\keytool.exe"
)

foreach ($path in $javaPaths) {
    $found = Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $keytoolPath = $found.FullName
        break
    }
}

if (-not $keytoolPath) {
    try {
        $keytoolPath = (Get-Command keytool -ErrorAction Stop).Source
    } catch {
        # Not found
    }
}

if (-not $keytoolPath) {
    Write-Host "❌ Không tìm thấy keytool!" -ForegroundColor Red
    Write-Host "Hãy cài đặt JDK hoặc chạy lệnh thủ công:" -ForegroundColor Yellow
    Write-Host 'keytool -list -v -keystore android\keystore\release.keystore -alias sos-release-key -storepass sosapp2024!' -ForegroundColor Gray
    exit 1
}

$keystorePath = Join-Path $PSScriptRoot "keystore\release.keystore"

if (-not (Test-Path $keystorePath)) {
    Write-Host "❌ Keystore không tồn tại: $keystorePath" -ForegroundColor Red
    Write-Host "Hãy chạy: .\android\create-keystore.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "Đang lấy thông tin keystore..." -ForegroundColor Cyan
Write-Host ""

$alias = "sos-release-key"
$storePass = "sosapp2024!"

$output = & "$keytoolPath" -list -v -keystore "$keystorePath" -alias "$alias" -storepass "$storePass" 2>&1

# Extract SHA-1
$sha1 = $output | Select-String -Pattern "SHA1:\s*([A-F0-9:]+)" | ForEach-Object { $_.Matches.Groups[1].Value }
$sha256 = $output | Select-String -Pattern "SHA256:\s*([A-F0-9:]+)" | ForEach-Object { $_.Matches.Groups[1].Value }

if ($sha1) {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  ✅ Thông tin Certificate" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "SHA-1:   $sha1" -ForegroundColor Cyan
    Write-Host "SHA-256: $sha256" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  Bước tiếp theo:" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Copy SHA-1 ở trên" -ForegroundColor White
    Write-Host ""
    Write-Host "2. Mở Firebase Console:" -ForegroundColor White
    Write-Host "   https://console.firebase.google.com/" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Chọn project: sos-app-d2109" -ForegroundColor White
    Write-Host ""
    Write-Host "4. Project Settings > Your apps > Android app" -ForegroundColor White
    Write-Host ""
    Write-Host "5. Scroll xuống 'SHA certificate fingerprints'" -ForegroundColor White
    Write-Host ""
    Write-Host "6. Click 'Add fingerprint' và paste SHA-1" -ForegroundColor White
    Write-Host ""
    Write-Host "7. Click 'Save' và download google-services.json mới" -ForegroundColor White
    Write-Host ""
    Write-Host "8. Replace file google-services.json trong:" -ForegroundColor White
    Write-Host "   android\app\google-services.json" -ForegroundColor Gray
    Write-Host ""
    Write-Host "9. Build APK:" -ForegroundColor White
    Write-Host "   flutter clean" -ForegroundColor Gray
    Write-Host "   flutter build apk --release" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "❌ Không lấy được SHA-1" -ForegroundColor Red
    Write-Host ""
    Write-Host "Output:" -ForegroundColor Yellow
    Write-Host $output
}
