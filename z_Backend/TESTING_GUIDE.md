# 🧪 HƯỚNG DẪN TEST HỆ THỐNG SOS

## Chuẩn Bị

### 1. Kiểm tra Server đang chạy
```bash
# Server phải đang chạy tại http://localhost:5000
# Xem log terminal npm run dev
```

### 2. Tạo Test Accounts (nếu chưa có)

**User Account:**
- Phone: `0912345678`
- Password: `password123`

**Volunteer Account (optional):**
- Phone: `0987654321`  
- Password: `password123`

---

## 🎯 TEST 1: PROGRESSIVE BAN (ĐƠN GIẢN NHẤT)

### Chạy Test:
```bash
cd z_Backend
node test-progressive-ban.js
```

### Expected Output:
```
✅ Attempt #1: SOS created successfully
✅ Attempt #2: SOS created successfully  
✅ Attempt #3: SOS created successfully
🚫 Attempt #4: BANNED!
   Message: Bạn đã gửi quá nhiều yêu cầu...

✅ TEST PASSED!
```

### Nếu Fail:
- Check user account có tồn tại không
- Check MongoDB connection
- Xem console log server có errors không

---

## 🎯 TEST 2: COMPREHENSIVE SYSTEM (FULL)

### Chạy Test:
```bash
cd z_Backend
node test-complete-system.js
```

### Expected Output:
```
📝 TEST 1: PROGRESSIVE BAN SYSTEM
✅ TEST 1 PASSED

📝 TEST 2: TIMEOUT MECHANISM  
✅ TEST 2 PASSED (nếu có TNV trong DB)

📝 TEST 3: AUTO-CANCEL MECHANISM
✅ TEST 3 PASSED

📊 TEST SUMMARY
Total Tests: 3
Passed: 3
✅ ALL TESTS PASSED!
```

---

## 🎯 TEST 3: MANUAL TEST (Sử dụng App/Postman)

### Step 1: Test Progressive Ban
1. Login vào app bằng account `0912345678`
2. Gửi SOS lần 1 → Success → Cancel
3. Gửi SOS lần 2 → Success → Cancel
4. Gửi SOS lần 3 → Success → Cancel
5. Gửi SOS lần 4 → Sẽ thấy error: "Bạn đã gửi quá nhiều yêu cầu"

### Step 2: Test Timeout (cần 2 devices)
1. Device 1 (User): Gửi SOS
2. Device 2 (TNV): Nhận notification
3. TNV KHÔNG bấm gì cả (ignore)
4. Chờ 30 giây
5. **Expected:** TNV tiếp theo nhận notification (nếu có)

### Step 3: Test Auto-Cancel
1. Tạm tắt tất cả TNV (set ready = false trong DB)
2. User gửi SOS
3. Chờ 30 giây
4. **Expected:** User nhận notification "Không tìm thấy TNV"

---

## 📊 Verify Logs

### Check Winston Logs:
```bash
# Error logs
cat z_Backend/logs/error.log

# SOS operations logs  
cat z_Backend/logs/sos-operations.log
```

### Expected Log Entries:

**User Banned:**
```json
{
  "level": "warn",
  "message": "User banned",
  "userId": "...",
  "reason": "spam",
  "banUntil": "2025-12-04T10:00:00.000Z"
}
```

**Queue Expired:**
```json
{
  "level": "info", 
  "message": "Queue expired",
  "volunteerId": "...",
  "caseId": "..."
}
```

---

## 🐛 Troubleshooting

### Test fails with "Login failed"
➡️ Tạo user bằng app hoặc Postman:
```bash
POST http://localhost:5000/api/auth/register
{
  "fullName": "Test User",
  "phone": "0912345678",
  "password": "password123"
}
```

### Test fails with "MongoDB connection failed"
➡️ Check MongoDB đang chạy:
```bash
# Windows
net start MongoDB

# Mac/Linux
sudo systemctl start mongod
```

### Timeout test không pass
➡️ Cần có ít nhất 1 TNV trong database
➡️ TNV phải có status = 'APPROVED' và ready = true

---

## ✅ Success Criteria

Hệ thống được coi là hoạt động tốt khi:

- ✅ **Progressive Ban:** Lần thử thứ 4 nhận error 429
- ✅ **Timeout:** Queue items chuyển sang EXPIRED sau 30s
- ✅ **Auto-Cancel:** Case chuyển sang CANCELLED khi hết TNV
- ✅ **Logs:** Winston ghi logs vào file đúng format
- ✅ **Cron Job:** Console log "🚀 Starting cleanup queue job"

---

## 📞 Quick Commands

```bash
# Chạy quick test
node test-progressive-ban.js

# Chạy full test  
node test-complete-system.js

# Reset user ban status (nếu bị stuck)
# Vào Mongo shell:
db.users.updateMany({}, { $set: { sosBanUntil: null } })

# Clear rate limit logs
db.sos_rate_limit_logs.deleteMany({})

# Check cron job logs
# Xem terminal npm run dev, tìm:
# "🚀 Starting cleanup queue job"
# "⏰ Expired X items for case..."
```
