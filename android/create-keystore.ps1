# Script tạo Release Keystore cho SOS App
# PowerShell script to create Android release keystore

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Tạo Release Keystore - SOS App" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Find keytool
$keytoolPath = $null

# Method 1: Check common Java locations
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

# Method 2: Try command line
if (-not $keytoolPath) {
    try {
        $keytoolPath = (Get-Command keytool -ErrorAction Stop).Source
    } catch {
        # Keytool not found in PATH
    }
}

if (-not $keytoolPath) {
    Write-Host "❌ Không tìm thấy keytool!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Keytool thường nằm trong JDK. Hãy cài đặt JDK hoặc:" -ForegroundColor Yellow
    Write-Host "1. Mở Android Studio" -ForegroundColor Yellow
    Write-Host "2. Build > Generate Signed Bundle/APK..." -ForegroundColor Yellow
    Write-Host "3. Chọn APK > Next" -ForegroundColor Yellow
    Write-Host "4. Click 'Create new...' để tạo keystore" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Thông tin keystore:" -ForegroundColor Cyan
    Write-Host "  Key store path: $PSScriptRoot\keystore\release.keystore" -ForegroundColor White
    Write-Host "  Password: sosapp2024!" -ForegroundColor White
    Write-Host "  Alias: sos-release-key" -ForegroundColor White
    Write-Host "  Validity: 10000 days" -ForegroundColor White
    Write-Host ""
    Write-Host "Hoặc tìm keytool và chạy lệnh thủ công:" -ForegroundColor Yellow
    Write-Host 'keytool -genkey -v -keystore android\keystore\release.keystore -alias sos-release-key -keyalg RSA -keysize 2048 -validity 10000' -ForegroundColor Gray
    Write-Host ""
    exit 1
}

Write-Host "✅ Tìm thấy keytool: $keytoolPath" -ForegroundColor Green
Write-Host ""

# Create keystore directory if not exists
$keystoreDir = Join-Path $PSScriptRoot "android\keystore"
if (-not (Test-Path $keystoreDir)) {
    New-Item -ItemType Directory -Path $keystoreDir -Force | Out-Null
}

$keystorePath = Join-Path $keystoreDir "release.keystore"

# Check if keystore already exists
if (Test-Path $keystorePath) {
    Write-Host "⚠️  Keystore đã tồn tại: $keystorePath" -ForegroundColor Yellow
    $overwrite = Read-Host "Bạn có muốn tạo lại? (y/n)"
    if ($overwrite -ne "y") {
        Write-Host "Hủy tạo keystore." -ForegroundColor Gray
        exit 0
    }
    Remove-Item $keystorePath -Force
}

# Keystore information
$storePass = "sosapp2024!"
$keyPass = "sosapp2024!"
$alias = "sos-release-key"
$dname = "CN=SOS App UTH, OU=Mobile Development, O=SOS App UTH, L=Ho Chi Minh City, ST=Ho Chi Minh, C=VN"

Write-Host "Đang tạo keystore..." -ForegroundColor Cyan
Write-Host ""

# Generate keystore
$cmd = "& `"$keytoolPath`" -genkey -v -keystore `"$keystorePath`" -alias `"$alias`" -keyalg RSA -keysize 2048 -validity 10000 -storepass `"$storePass`" -keypass `"$keyPass`" -dname `"$dname`""

try {
    Invoke-Expression $cmd
    
    if (Test-Path $keystorePath) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "  ✅ Tạo keystore thành công!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "📁 Keystore path: $keystorePath" -ForegroundColor Cyan
        Write-Host "🔑 Alias: $alias" -ForegroundColor Cyan
        Write-Host "🔒 Store Password: $storePass" -ForegroundColor Cyan
        Write-Host "🔒 Key Password: $keyPass" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "⚠️  LƯU NHỮNG THÔNG TIN SAU:" -ForegroundColor Yellow
        Write-Host "1. SAO LƯU file keystore này ở nơi an toàn" -ForegroundColor Yellow
        Write-Host "2. KHÔNG commit keystore lên Git" -ForegroundColor Yellow
        Write-Host "3. GHI NHỚ password (hoặc lưu vào password manager)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Bước tiếp theo:" -ForegroundColor Cyan
        Write-Host "1. Lấy SHA-1 fingerprint bằng lệnh:" -ForegroundColor White
        Write-Host "   .\android\get-sha1.ps1" -ForegroundColor Gray
        Write-Host "2. Thêm SHA-1 vào Firebase Console" -ForegroundColor White
        Write-Host "3. Build APK: flutter build apk --release" -ForegroundColor White
        Write-Host ""
    } else {
        throw "Keystore file không được tạo"
    }
} catch {
    Write-Host ""
    Write-Host "❌ Lỗi tạo keystore: $_" -ForegroundColor Red
    Write-Host ""
    exit 1
}
