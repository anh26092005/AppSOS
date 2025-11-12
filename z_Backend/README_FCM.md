# Firebase Cloud Messaging (FCM) Integration

## Tổng quan

Hệ thống đã được tích hợp Firebase Cloud Messaging để gửi thông báo đẩy cho tình nguyện viên khi có trường hợp SOS khẩn cấp mới.

## Files đã thêm/cập nhật

### Files mới:
- `services/fcm.service.js` - Service quản lý FCM
- `controllers/device.controller.js` - Controller quản lý devices
- `routes/device.routes.js` - Routes cho device API
- `config/FCM_SETUP_GUIDE.md` - Hướng dẫn chi tiết cấu hình FCM
- `.env.example` - Template file environment variables

### Files đã cập nhật:
- `package.json` - Thêm firebase-admin dependency
- `controllers/sos.controller.js` - Tích hợp gửi FCM khi tìm volunteers
- `routes/index.js` - Thêm device routes
- `server.js` - Khởi tạo Firebase khi start server
- `.gitignore` - Ignore firebase service account file

## Cấu hình nhanh

### 1. Cài đặt dependencies (Đã hoàn thành)

```bash
cd z_Backend
npm install
```

### 2. Cấu hình Firebase Service Account

**Cách 1: Sử dụng biến môi trường (Production)**

Tạo file `.env` và thêm:

```env
FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"...","private_key":"..."}
```

**Cách 2: Sử dụng file config (Development)**

Đặt file `firebase-service-account.json` vào `config/`:

```
z_Backend/config/firebase-service-account.json
```

### 3. Khởi động server

```bash
npm start
```

Kiểm tra log:
- ✅ "Firebase initialized successfully" → Hoạt động tốt
- ⚠️ "Firebase initialization failed" → Server vẫn chạy nhưng không có FCM

## API Endpoints

### Đăng ký Device Token

```http
POST /api/devices/register
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json

{
  "pushToken": "fcm-token-here",
  "platform": "ANDROID",
  "latitude": 10.762622,
  "longitude": 106.660172
}
```

### Xóa Device Token

```http
POST /api/devices/unregister
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json

{
  "pushToken": "fcm-token-here"
}
```

### Lấy danh sách devices

```http
GET /api/devices
Authorization: Bearer <JWT_TOKEN>
```

## Cách hoạt động

1. **User đăng nhập** → App lấy FCM token → Đăng ký với backend qua API `/api/devices/register`

2. **SOS case mới** → Backend tự động:
   - Tìm volunteers gần nhất (trong bán kính 50km)
   - Lưu vào queue
   - **Gửi FCM notification cho tất cả volunteers**

3. **Volunteer nhận notification** → Tap notification → Mở app → Xem chi tiết case

## Notification Format

**Title:** "🚨 Có trường hợp khẩn cấp cần hỗ trợ"

**Body:** "{EMERGENCY_TYPE} - Cách bạn {distance}km"

**Data:**
```json
{
  "type": "SOS_CASE",
  "caseId": "...",
  "caseCode": "SOS...",
  "emergencyType": "MEDICAL",
  "distance": "2.3"
}
```

## Xử lý lỗi

- Token không hợp lệ → **Tự động xóa** khỏi database
- FCM service lỗi → **Không ảnh hưởng** đến SOS flow chính
- Firebase chưa config → Server **vẫn chạy bình thường** (không có FCM)

## Tài liệu chi tiết

Xem `config/FCM_SETUP_GUIDE.md` để biết:
- Hướng dẫn tạo Firebase project
- Cách lấy service account key
- Cấu hình Flutter app (Android/iOS)
- Troubleshooting và best practices

## Testing

1. **Test đăng ký device:**

```bash
curl -X POST http://localhost:5000/api/devices/register \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "pushToken": "test-token-123",
    "platform": "ANDROID"
  }'
```

2. **Test tạo SOS case:**

```bash
curl -X POST http://localhost:5000/api/sos \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "latitude": 10.762622,
    "longitude": 106.660172,
    "emergencyType": "MEDICAL",
    "description": "Test emergency"
  }'
```

→ Volunteers gần nhất sẽ nhận được FCM notification

## Lưu ý bảo mật

⚠️ **QUAN TRỌNG:**
- **KHÔNG** commit file `firebase-service-account.json` lên Git
- **KHÔNG** share service account key
- Sử dụng environment variables cho production
- Rotate keys định kỳ

## Support

Nếu gặp vấn đề, kiểm tra:
1. Log server khi khởi động
2. Firebase Console > Cloud Messaging
3. Device token có đăng ký thành công không
4. Database collection `devices` có data không

Xem thêm: `config/FCM_SETUP_GUIDE.md`

