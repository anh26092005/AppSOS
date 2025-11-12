# Environment Variables Template

Copy nội dung dưới đây vào file `.env` trong thư mục `z_Backend/`

```env
# ============================================
# SERVER CONFIGURATION
# ============================================
PORT=5000
HOST=0.0.0.0

# ============================================
# DATABASE CONFIGURATION
# ============================================
MONGO_URI=mongodb://localhost:27017/sos_app

# ============================================
# JWT CONFIGURATION
# ============================================
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRES_IN=7d

# ============================================
# CORS CONFIGURATION
# ============================================
# Comma-separated list of allowed origins
CORS_ORIGINS=http://localhost:3000,http://localhost:5173

# ============================================
# AWS S3 CONFIGURATION (Optional)
# ============================================
AWS_ACCESS_KEY_ID=your-aws-access-key-id
AWS_SECRET_ACCESS_KEY=your-aws-secret-access-key
AWS_REGION=ap-southeast-1
AWS_S3_BUCKET=your-s3-bucket-name

# ============================================
# FIREBASE CLOUD MESSAGING (FCM) CONFIGURATION
# ============================================

# Option 1: Provide Firebase service account as JSON string (Recommended for Production)
# Lấy từ Firebase Console > Project Settings > Service Accounts > Generate new private key
# Copy toàn bộ nội dung file JSON vào một dòng duy nhất
# FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"your-project-id","private_key_id":"your-key-id","private_key":"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n","client_email":"your-service-account@project.iam.gserviceaccount.com","client_id":"123456789","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"https://www.googleapis.com/robot/v1/metadata/x509/..."}

# Option 2: Or place the service account JSON file at:
# z_Backend/config/firebase-service-account.json
# (This file is already in .gitignore for security)

# ============================================
# NOTES
# ============================================
# 1. Copy this template to .env and fill in your actual values
# 2. NEVER commit .env to version control
# 3. For production, use secure secret management (e.g., AWS Secrets Manager, Azure Key Vault)
# 4. JWT_SECRET should be a long random string (minimum 32 characters)
# 5. Firebase service account contains sensitive credentials - keep it secure
```

## Tạo file .env

```bash
# Windows PowerShell
cd z_Backend
Copy-Item ENV_TEMPLATE.md .env

# Linux/Mac
cd z_Backend
cp ENV_TEMPLATE.md .env
```

Sau đó chỉnh sửa file `.env` và điền các giá trị thực tế.

## Lấy Firebase Service Account

1. Truy cập [Firebase Console](https://console.firebase.google.com/)
2. Chọn project của bạn
3. Vào **Project Settings** (⚙️) > **Service Accounts**
4. Click **Generate new private key**
5. Tải file JSON về

**Sử dụng:**
- **Option 1:** Copy toàn bộ nội dung JSON vào biến `FIREBASE_SERVICE_ACCOUNT` (một dòng duy nhất)
- **Option 2:** Đặt file vào `z_Backend/config/firebase-service-account.json`

## Generate JWT_SECRET

Tạo chuỗi ngẫu nhiên an toàn:

**Node.js:**
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

**OpenSSL:**
```bash
openssl rand -hex 32
```

**PowerShell:**
```powershell
-join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | % {[char]$_})
```

