# Hướng Dẫn Sử Dụng Avatar API Tests

## 📋 Mô tả
Collection Postman này chứa các test cases để kiểm tra API upload và update avatar cho user trong hệ thống Safe Connect.

## 🔧 Cài đặt

### 1. Import Collection vào Postman
1. Mở Postman
2. Click **Import** ở góc trên bên trái
3. Chọn file `Avatar_API_Tests.postman_collection.json`
4. Click **Import**

### 2. Thiết lập Environment
Tạo một Environment mới trong Postman với các biến sau:

| Variable | Initial Value | Description |
|----------|---------------|-------------|
| `base_url` | `http://localhost:5000/api` | Base URL của API (hoặc Cloudflare URL) |
| `auth_token` | (để trống) | Token sẽ được tự động lưu sau khi login |
| `user_id` | (để trống) | User ID sẽ được tự động lưu sau khi login |
| `avatar_url` | (để trống) | Avatar URL sẽ được tự động lưu sau khi upload |
| `avatar_key` | (để trống) | Avatar S3 key sẽ được tự động lưu |

**Lưu ý:** Nếu bạn đang dùng Cloudflare Tunnel, thay đổi `base_url` thành:
```
https://your-tunnel-url.trycloudflare.com/api
```

## 📂 Cấu trúc Collection

### 1. Authentication (Xác thực)
- **Login để lấy Token**: Login và tự động lưu token vào environment
- **Get Profile (Verify Token)**: Kiểm tra token có hợp lệ không

### 2. Avatar Upload (Upload Avatar)
- **Upload Avatar - Success**: Upload avatar thành công
- **Upload Avatar - No File**: Test khi không gửi file
- **Upload Avatar - No Auth Token**: Test khi không có token
- **Upload Avatar - Invalid Token**: Test với token không hợp lệ
- **Upload Avatar - Large File**: Test với file lớn
- **Upload Avatar - Update Existing**: Test update avatar khi đã có avatar cũ

### 3. Verification (Xác minh)
- **Get Profile After Upload**: Kiểm tra avatar đã được update trong profile

## 🚀 Cách chạy Tests

### Chạy từng request riêng lẻ

1. **Bước 1: Login**
   - Mở request "Login để lấy Token"
   - Sửa email và password trong body:
     ```json
     {
         "email": "your-email@example.com",
         "password": "your-password"
     }
     ```
   - Click **Send**
   - Token sẽ tự động lưu vào environment

2. **Bước 2: Upload Avatar**
   - Mở request "Upload Avatar - Success"
   - Click vào tab **Body**
   - Chọn file ảnh bằng cách click **Select Files** ở field `avatar`
   - Click **Send**
   - Avatar URL sẽ tự động lưu vào environment

3. **Bước 3: Verify**
   - Mở request "Get Profile After Upload"
   - Click **Send**
   - Kiểm tra response có chứa avatar data không

### Chạy toàn bộ Collection

1. Click vào menu **...** (ba chấm) bên cạnh tên collection
2. Chọn **Run collection**
3. Trong màn hình Collection Runner:
   - Chọn môi trường (Environment) đã tạo
   - Bỏ chọn các test case yêu cầu file upload (vì không thể tự động)
   - Click **Run Avatar API Tests**

## ✅ Test Cases Chi Tiết

### TC1: Upload Avatar - Success
**Mục đích:** Test upload avatar thành công

**Pre-conditions:**
- User đã đăng nhập và có token hợp lệ
- File ảnh hợp lệ (jpg, png, gif, webp)
- File size < 5MB

**Steps:**
1. Chuẩn bị file ảnh avatar
2. Gửi PUT request với Bearer token
3. Attach file vào field `avatar`

**Expected Results:**
- Status code: 200
- Response body:
  ```json
  {
    "success": true,
    "data": {
      "avatar": {
        "url": "https://s3.amazonaws.com/...",
        "key": "avatars/...",
        "bucket": "your-bucket-name"
      }
    },
    "message": "Avatar updated successfully"
  }
  ```

### TC2: Upload Avatar - No File
**Mục đích:** Test khi không gửi file

**Expected Results:**
- Status code: 400
- Error message: "No avatar file provided"

### TC3: Upload Avatar - No Auth Token
**Mục đích:** Test khi không có authentication

**Expected Results:**
- Status code: 401
- Error message: Unauthorized

### TC4: Upload Avatar - Invalid Token
**Mục đích:** Test với token không hợp lệ

**Expected Results:**
- Status code: 401
- Error message: Invalid token

### TC5: Upload Avatar - Large File
**Mục đích:** Test với file > 5MB

**Expected Results:**
- Status code: 413 (Payload Too Large) hoặc 400
- Error message về file size limit

### TC6: Upload Avatar - Update Existing
**Mục đích:** Test update avatar khi đã có avatar cũ

**Pre-conditions:**
- User đã có avatar

**Expected Results:**
- Status code: 200
- Avatar mới được upload thành công
- Avatar cũ bị xóa khỏi S3

## 🧪 Automated Tests

Mỗi request đều có automated tests được viết bằng JavaScript:

```javascript
// Kiểm tra status code
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

// Kiểm tra response structure
pm.test("Avatar data is returned", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.data.avatar).to.exist;
    pm.expect(jsonData.data.avatar.url).to.exist;
});

// Lưu data vào environment
pm.environment.set("avatar_url", jsonData.data.avatar.url);
```

## 📝 Lưu ý quan trọng

1. **Token Expiration**: Token có thể hết hạn, nếu gặp lỗi 401 thì cần login lại
2. **File Size Limit**: Avatar có giới hạn 5MB
3. **File Types**: Chỉ chấp nhận: jpg, jpeg, png, gif, webp
4. **S3 Cleanup**: Avatar cũ sẽ tự động bị xóa khi upload avatar mới
5. **Environment Variables**: Đảm bảo đã setup environment variables đúng

## 🐛 Troubleshooting

### Lỗi: "No avatar file provided"
- Kiểm tra đã chọn file trong field `avatar` chưa
- Đảm bảo field name là `avatar` (không phải `file` hay tên khác)

### Lỗi: "Unauthorized"
- Kiểm tra token trong environment
- Thử login lại để lấy token mới
- Đảm bảo Bearer token được set đúng trong Authorization

### Lỗi: "File too large"
- Giảm kích thước file xuống dưới 5MB
- Compress ảnh trước khi upload

### Lỗi: "Invalid file type"
- Chỉ sử dụng file ảnh: jpg, png, gif, webp
- Kiểm tra extension của file

## 📊 Test Results Example

Khi chạy collection, bạn sẽ thấy kết quả như sau:

```
✓ Login để lấy Token
  ✓ Status code is 200
  ✓ Response has token
  ✓ Token saved to environment

✓ Upload Avatar - Success
  ✓ Status code is 200
  ✓ Response contains success message
  ✓ Avatar data is returned
  ✓ Avatar URL is valid
  ✓ Save avatar data

✓ Get Profile After Upload
  ✓ Status code is 200
  ✓ Profile contains avatar data
  ✓ Avatar URL matches uploaded avatar
```

## 🔗 API Endpoint

```
PUT /api/auth/avatar
```

**Headers:**
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Body (form-data):**
```
avatar: <file>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "_id": "user_id",
    "fullName": "User Name",
    "email": "user@example.com",
    "avatar": {
      "bucket": "bucket-name",
      "key": "avatars/1234567890-avatar.jpg",
      "url": "https://s3.amazonaws.com/bucket/avatars/1234567890-avatar.jpg",
      "mimeType": "image/jpeg",
      "size": 123456,
      "etag": "etag-value"
    }
  },
  "message": "Avatar updated successfully"
}
```

## 📞 Support

Nếu gặp vấn đề, hãy kiểm tra:
1. Backend server đang chạy (port 5000)
2. Environment variables đã được setup đúng
3. AWS S3 credentials đã được cấu hình
4. File upload có đúng format và size không

---

**Người tạo:** AI Assistant  
**Ngày tạo:** 2025-11-28  
**Version:** 1.0
