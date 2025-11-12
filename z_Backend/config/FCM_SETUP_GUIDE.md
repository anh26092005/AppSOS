# Firebase Cloud Messaging (FCM) Setup Guide

Hướng dẫn cấu hình Firebase Cloud Messaging để gửi thông báo đẩy cho ứng dụng SOS.

## Bước 1: Tạo Firebase Project

1. Truy cập [Firebase Console](https://console.firebase.google.com/)
2. Tạo project mới hoặc chọn project hiện có
3. Vào **Project Settings** (biểu tượng bánh răng bên cạnh "Project Overview")

## Bước 2: Tạo Service Account Key

1. Trong **Project Settings**, chọn tab **Service Accounts**
2. Click nút **Generate new private key**
3. Xác nhận và tải file JSON về máy (ví dụ: `firebase-service-account.json`)

⚠️ **LƯU Ý BẢO MẬT:** File này chứa thông tin nhạy cảm, KHÔNG được commit lên Git!

## Bước 3: Cấu hình Backend

Có **2 cách** để cấu hình Firebase service account:

### Cách 1: Sử dụng biến môi trường (Khuyến nghị cho Production)

Thêm vào file `.env`:

```env
FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"your-project-id","private_key_id":"...","private_key":"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n","client_email":"...","client_id":"...","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"..."}
```

**Lưu ý:** 
- Phải là một dòng JSON hợp lệ (không có xuống dòng)
- Private key phải giữ nguyên ký tự `\n` để đại diện cho xuống dòng

### Cách 2: Sử dụng file config (Khuyến nghị cho Development)

1. Copy file `firebase-service-account.json` vào thư mục `z_Backend/config/`
2. Thêm vào `.gitignore`:

```
# Firebase
config/firebase-service-account.json
```

Cấu trúc file:

```
z_Backend/
├── config/
│   ├── firebase-service-account.json  ← Đặt file ở đây
│   ├── db.js
│   └── ...
```

## Bước 4: Cấu hình Flutter App (Frontend)

### Android

1. Tải file `google-services.json` từ Firebase Console
2. Đặt vào `android/app/google-services.json`
3. Cấu hình trong `android/build.gradle` và `android/app/build.gradle`

### iOS

1. Tải file `GoogleService-Info.plist` từ Firebase Console
2. Thêm vào Xcode project

## API Endpoints

### 1. Đăng ký Device Token

```http
POST /api/devices/register
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json

{
  "pushToken": "fcm-device-token-here",
  "platform": "ANDROID",
  "latitude": 10.762622,
  "longitude": 106.660172
}
```

**Response:**

```json
{
  "success": true,
  "data": {
    "_id": "...",
    "userId": "...",
    "platform": "ANDROID",
    "pushToken": "...",
    "lastLocation": {
      "type": "Point",
      "coordinates": [106.660172, 10.762622]
    },
    "lastSeenAt": "2024-01-01T00:00:00.000Z",
    "createdAt": "2024-01-01T00:00:00.000Z"
  },
  "message": "Device registered successfully"
}
```

### 2. Xóa Device Token

```http
POST /api/devices/unregister
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json

{
  "pushToken": "fcm-device-token-here"
}
```

### 3. Lấy danh sách devices

```http
GET /api/devices
Authorization: Bearer <JWT_TOKEN>
```

## Flow hoạt động

1. **User mở app** → Lấy FCM token → Gọi API `/api/devices/register`
2. **SOS case mới được tạo** → Backend tìm volunteers gần nhất
3. **Gửi FCM notification** → Volunteer nhận thông báo trên điện thoại
4. **Volunteer tap notification** → Mở app và xem chi tiết case

## Notification Data Structure

Khi có SOS case mới, volunteers sẽ nhận notification với:

**Notification:**
- Title: "🚨 Có trường hợp khẩn cấp cần hỗ trợ"
- Body: "MEDICAL - Cách bạn 2.3km"

**Data:**
```json
{
  "type": "SOS_CASE",
  "caseId": "64abc123...",
  "caseCode": "SOS1234567890ABCD",
  "emergencyType": "MEDICAL",
  "distance": "2.3"
}
```

## Kiểm tra cấu hình

1. Khởi động server:

```bash
cd z_Backend
npm start
```

2. Kiểm tra log:
   - ✅ "Firebase initialized successfully" → Cấu hình đúng
   - ❌ "Firebase initialization failed" → Kiểm tra lại cấu hình

## Troubleshooting

### Lỗi: "Firebase service account not found"

**Nguyên nhân:** Chưa cấu hình service account

**Giải pháp:**
- Thêm biến `FIREBASE_SERVICE_ACCOUNT` vào `.env`, hoặc
- Đặt file `firebase-service-account.json` vào `config/`

### Lỗi: "Invalid FIREBASE_SERVICE_ACCOUNT JSON format"

**Nguyên nhân:** JSON string không hợp lệ

**Giải pháp:**
- Đảm bảo JSON string là một dòng duy nhất
- Kiểm tra không có ký tự xuống dòng thật (chỉ `\n` trong string)
- Sử dụng tool minify JSON nếu cần

### Lỗi: "messaging/invalid-registration-token"

**Nguyên nhân:** Token không hợp lệ hoặc đã hết hạn

**Giải pháp:**
- Backend tự động xóa token không hợp lệ
- App cần đăng ký lại token mới

## Best Practices

1. **Security:**
   - KHÔNG commit file service account lên Git
   - Sử dụng environment variables cho production
   - Rotate keys định kỳ

2. **Error Handling:**
   - Backend không throw error nếu FCM thất bại
   - Server vẫn hoạt động bình thường nếu chưa config FCM
   - Log errors để debug

3. **Token Management:**
   - Đăng ký token khi user login
   - Cập nhật token khi refresh
   - Xóa token khi user logout

4. **Testing:**
   - Test với cả Android và iOS
   - Kiểm tra notification khi app foreground/background
   - Verify data payload được parse đúng

