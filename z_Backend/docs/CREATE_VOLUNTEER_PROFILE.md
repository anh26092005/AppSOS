# Hướng dẫn tạo Volunteer Profile để test thông báo SOS

## API đã tạo

**Endpoint**: `POST /api/volunteers`  
**Authentication**: Required (Bearer Token)  
**Authorization**: Không cần ADMIN role

## Request Body

```json
{
  "userId": "YOUR_USER_ID_HERE",
  "type": "CN",
  "homeBase": {
    "location": {
      "coordinates": [106.660172, 10.762622]
    },
    "radiusKm": 5
  },
  "skills": ["First Aid", "CPR"],
  "organization": {
    "name": "Test Organization",
    "address": "123 Test Street",
    "contactPhone": "0123456789"
  }
}
```

### Các trường bắt buộc:
- ✅ `userId` - ID của user (phải tồn tại trong database)
- ✅ `type` - Loại TNV: `"CN"` (Cá nhân) hoặc `"TC"` (Tổ chức)
- ✅ `homeBase.location.coordinates` - Tọa độ [longitude, latitude]

### Các trường tùy chọn:
- `homeBase.radiusKm` - Bán kính hoạt động (mặc định 5km)
- `skills` - Mảng kỹ năng
- `organization` - Thông tin tổ chức (nếu type = "TC")
- `idCardFront` - Ảnh CMND mặt trước
- `idCardBack` - Ảnh CMND mặt sau

## Các bước thực hiện

### Bước 1: Lấy User ID

Đăng nhập và lấy user ID của bạn. Có thể gọi API:
```http
GET /api/auth/me
Authorization: Bearer YOUR_TOKEN
```

### Bước 2: Tạo Volunteer Profile

```http
POST http://localhost:5000/api/volunteers
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN

{
  "userId": "67461d96f36e01ad64af3db0",
  "type": "CN",
  "homeBase": {
    "location": {
      "coordinates": [106.660172, 10.762622]
    },
    "radiusKm": 10
  },
  "skills": ["First Aid"]
}
```

### Bước 3: Approve Volunteer Profile (cần ADMIN)

Vì profile mới tạo có `status: "PENDING"`, bạn cần approve nó:

```http
POST http://localhost:5000/api/volunteers/{VOLUNTEER_PROFILE_ID}/approve
Authorization: Bearer ADMIN_TOKEN
```

Sau khi approve:
- ✅ `status` sẽ thành `"APPROVED"`
- ✅ `ready` sẽ thành `true`
- ✅ User sẽ được thêm role `TNV_CN` hoặc `TNV_TC`

### Bước 4: Test thông báo SOS

Tạo SOS case mới:

```http
POST http://localhost:5000/api/sos/cases
Content-Type: application/json
Authorization: Bearer USER_TOKEN

{
  "latitude": 10.762622,
  "longitude": 106.660172,
  "emergencyType": "ACCIDENT",
  "description": "Test notification",
  "isUrgent": true
}
```

Kiểm tra xem TNV đã nhận được notification chưa!

## Lưu ý quan trọng

> [!IMPORTANT]
> - Vị trí `homeBase.location.coordinates` phải ở định dạng [longitude, latitude] (kinh độ trước, vĩ độ sau)
> - Mỗi user chỉ có thể có 1 volunteer profile
> - Profile mới tạo sẽ có status là `PENDING` và cần được admin approve

## Ví dụ với Postman

1. **Tạo collection mới** "Volunteer API"
2. **Tạo request** "Create Volunteer Profile"
   - Method: POST
   - URL: `http://localhost:5000/api/volunteers`
   - Headers: 
     - `Content-Type: application/json`
     - `Authorization: Bearer {{token}}`
   - Body (raw JSON):
     ```json
     {
       "userId": "{{userId}}",
       "type": "CN",
       "homeBase": {
         "location": {
           "coordinates": [106.660172, 10.762622]
         }
       }
     }
     ```

3. **Tạo request** "Approve Volunteer"
   - Method: POST
   - URL: `http://localhost:5000/api/volunteers/{{profileId}}/approve`
   - Headers: `Authorization: Bearer {{adminToken}}`
