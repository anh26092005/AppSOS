# Thông tin Release Keystore - SOS App

## Keystore Information
- **Keystore Path**: `android/keystore/release.keystore`
- **Keystore Password**: `sosapp2024!`
- **Key Alias**: `sos-release-key`
- **Key Password**: `sosapp2024!`

## Owner Information
- **Organization**: SOS App UTH
- **Organizational Unit**: Mobile Development
- **City**: Ho Chi Minh City
- **State**: Ho Chi Minh
- **Country Code**: VN

## Validity
- Valid for: 10000 days (~27 years)

---

## Lệnh tạo keystore (đã chạy):

```bash
keytool -genkey -v -keystore android/keystore/release.keystore -alias sos-release-key -keyalg RSA -keysize 2048 -validity 10000
```

## Thông tin cho key.properties:

```properties
storePassword=sosapp2024!
keyPassword=sosapp2024!
keyAlias=sos-release-key
storeFile=../keystore/release.keystore
```

---

> **LƯU Ý QUAN TRỌNG:**
> - **KHÔNG** commit file `release.keystore` lên Git
> - **KHÔNG** commit file `key.properties` lên Git
> - **SAO LƯU** file keystore ở nơi an toàn
> - Nếu mất keystore, bạn sẽ KHÔNG THỂ update app trên Google Play Store

---

## Backup Keystore

**Nên copy file này sang:**
1. USB drive
2. Cloud storage (Google Drive, Dropbox - private)
3. Password manager (lưu file + password)

**Path to backup:**
```
d:\Dev\Code\Backend_SOS\AppSOS\android\keystore\release.keystore
```
