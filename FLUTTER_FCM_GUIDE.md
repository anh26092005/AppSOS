# Hướng dẫn tích hợp Firebase Cloud Messaging (FCM) vào Flutter App

Tài liệu này hướng dẫn chi tiết cách tích hợp FCM vào Flutter app để nhận push notification từ backend SOS.

---

## 📋 Mục lục

1. [Cài đặt và cấu hình](#1-cài-đặt-và-cấu-hình)
2. [Backend API Endpoints](#2-backend-api-endpoints)
3. [Tích hợp vào Flutter App](#3-tích-hợp-vào-flutter-app)
4. [Xử lý Notification](#4-xử-lý-notification)
5. [Test và Troubleshooting](#5-test-và-troubleshooting)

---
dart run flutter_launcher_icons
pun get

## 1. Cài đặt và cấu hình

### 1.1. Thêm Dependencies

Cập nhật `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
  
  # HTTP client (nếu chưa có)
  http: ^1.5.0
  
  # Storage để lưu JWT token (nếu chưa có)
  shared_preferences: ^2.2.2
```

Chạy:
```bash
flutter pub get
```

### 1.2. Cấu hình Android

**Bước 1:** Tải file `google-services.json` từ Firebase Console:
- Firebase Console → Project Settings → Your apps → Android app
- Download `google-services.json`

**Bước 2:** Đặt file vào:
```
android/app/google-services.json
```

**Bước 3:** Cập nhật `android/build.gradle.kts`:

```kotlin
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

**Bước 4:** Cập nhật `android/app/build.gradle.kts`:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Thêm dòng này
}
```

### 1.3. Cấu hình iOS (nếu cần)

1. Tải `GoogleService-Info.plist` từ Firebase Console
2. Thêm vào Xcode project
3. Cấu hình trong Xcode

---
backend tui làm rồi nha
## 2. Backend API Endpoints

### 2.1. Đăng ký Device Token

**Endpoint:** `POST /api/devices/register`

**Headers:**
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

**Request Body:**
```json
{
  "pushToken": "fcm-token-here",
  "platform": "ANDROID",
  "latitude": 10.762622,
  "longitude": 106.660172
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "_id": "64abc123...",
    "userId": "64def456...",
    "platform": "ANDROID",
    "pushToken": "fcm-token-here",
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

**Lỗi (400 Bad Request):**
```json
{
  "success": false,
  "message": "Push token and platform are required"
}
```

### 2.2. Xóa Device Token

**Endpoint:** `POST /api/devices/unregister`

**Headers:**
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

**Request Body:**
```json
{
  "pushToken": "fcm-token-here"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Device unregistered successfully"
}
```

### 2.3. Lấy danh sách Devices

**Endpoint:** `GET /api/devices`

**Headers:**
```
Authorization: Bearer <JWT_TOKEN>
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "...",
      "platform": "ANDROID",
      "pushToken": "...",
      "lastSeenAt": "..."
    }
  ],
  "count": 1
}
```

---

## 3. Tích hợp vào Flutter App

### 3.1. Tạo Device Service

Tạo file `lib/services/device_service.dart`:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'fcm_service.dart';

class DeviceService {
  // Base URL - Thay đổi theo môi trường
  static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android Emulator
  // static const String baseUrl = 'http://localhost:5000/api'; // iOS Simulator
  // static const String baseUrl = 'https://your-domain.com/api'; // Production

  /// Lấy JWT token từ storage
  static Future<String?> _getJWTToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  /// Đăng ký FCM token với backend
  static Future<bool> registerDevice({
    String? latitude,
    String? longitude,
  }) async {
    try {
      // 1. Lấy FCM token
      String? fcmToken = await FCMService.getFCMToken();
      if (fcmToken == null) {
        print('❌ FCM token is null');
        return false;
      }

      // 2. Lấy JWT token
      String? jwtToken = await _getJWTToken();
      if (jwtToken == null) {
        print('❌ JWT token not found. User must login first.');
        return false;
      }

      // 3. Xác định platform
      String platform = Platform.isAndroid ? 'ANDROID' : 'IOS';

      // 4. Chuẩn bị request body
      Map<String, dynamic> body = {
        'pushToken': fcmToken,
        'platform': platform,
      };

      // Thêm location nếu có
      if (latitude != null && longitude != null) {
        body['latitude'] = double.parse(latitude);
        body['longitude'] = double.parse(longitude);
      }

      // 5. Gọi API
      final response = await http.post(
        Uri.parse('$baseUrl/devices/register'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      // 6. Xử lý response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Device registered: ${data['message']}');
        return true;
      } else {
        final error = jsonDecode(response.body);
        print('❌ Failed to register device: ${error['message']}');
        return false;
      }
    } catch (e) {
      print('❌ Error registering device: $e');
      return false;
    }
  }

  /// Xóa FCM token khỏi backend
  static Future<bool> unregisterDevice() async {
    try {
      // 1. Lấy FCM token
      String? fcmToken = FCMService.currentToken;
      if (fcmToken == null) {
        print('❌ FCM token is null');
        return false;
      }

      // 2. Lấy JWT token
      String? jwtToken = await _getJWTToken();
      if (jwtToken == null) {
        print('❌ JWT token not found');
        return false;
      }

      // 3. Gọi API
      final response = await http.post(
        Uri.parse('$baseUrl/devices/unregister'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pushToken': fcmToken,
        }),
      );

      // 4. Xử lý response
      if (response.statusCode == 200) {
        print('✅ Device unregistered successfully');
        return true;
      } else {
        print('❌ Failed to unregister device: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error unregistering device: $e');
      return false;
    }
  }

  /// Lấy danh sách devices của user
  static Future<List<Map<String, dynamic>>?> getMyDevices() async {
    try {
      String? jwtToken = await _getJWTToken();
      if (jwtToken == null) {
        print('❌ JWT token not found');
        return null;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/devices'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        print('❌ Failed to get devices: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error getting devices: $e');
      return null;
    }
  }
}
```

### 3.2. Cập nhật FCM Service

Cập nhật `lib/services/fcm_service.dart` để tự động đăng ký token khi refresh:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'device_service.dart'; // Import device service

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;

  /// Lấy FCM token
  static Future<String?> getFCMToken() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        _fcmToken = await _messaging.getToken();
        
        if (kDebugMode) {
          print('═══════════════════════════════════════════════════════════════');
          print('✅ FCM Token obtained:');
          print(_fcmToken);
          print('═══════════════════════════════════════════════════════════════');
        }
        
        return _fcmToken;
      } else {
        if (kDebugMode) {
          print('❌ Notification permission denied');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting FCM token: $e');
      }
      return null;
    }
  }

  /// Lắng nghe khi token refresh và tự động đăng ký lại
  static void setupTokenRefreshListener() {
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      if (kDebugMode) {
        print('🔄 FCM Token refreshed: $newToken');
      }
      
      // Tự động đăng ký token mới với backend
      DeviceService.registerDevice();
    });
  }

  /// Lấy token hiện tại
  static String? get currentToken => _fcmToken;

  /// Xóa token (dùng khi logout)
  static Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      if (kDebugMode) {
        print('✅ FCM Token deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting FCM token: $e');
      }
    }
  }

  /// Setup notification handlers
  static void setupNotificationHandlers() {
    // Xử lý notification khi app đang foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('📨 Notification received (foreground):');
        print('Title: ${message.notification?.title}');
        print('Body: ${message.notification?.body}');
        print('Data: ${message.data}');
      }
      
      // TODO: Hiển thị notification hoặc xử lý data
      // Xem phần 4. Xử lý Notification
    });

    // Xử lý khi user tap vào notification (app đang background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('📨 Notification tapped (background):');
        print('Data: ${message.data}');
      }
      
      // TODO: Navigate đến screen tương ứng
      // Xem phần 4. Xử lý Notification
    });
  }

  /// Kiểm tra notification đã được tap khi app terminated
  static Future<void> checkInitialMessage() async {
    RemoteMessage? initialMessage = 
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      if (kDebugMode) {
        print('📨 App opened from notification (terminated):');
        print('Data: ${initialMessage.data}');
      }
      
      // TODO: Navigate đến screen tương ứng
      // Xem phần 4. Xử lý Notification
    }
  }
}
```

### 3.3. Cập nhật Main.dart

Cập nhật `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'router_theme/routes.dart';
import 'router_theme/theme.dart';
import 'services/fcm_service.dart';
import 'services/device_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Firebase
  await Firebase.initializeApp();
  
  // Lấy FCM token và in ra console
  await FCMService.getFCMToken();
  
  // Setup notification handlers
  FCMService.setupNotificationHandlers();
  FCMService.checkInitialMessage();
  
  // Setup token refresh listener (tự động đăng ký lại khi token refresh)
  FCMService.setupTokenRefreshListener();
  
  runApp(const SOSApp());
}

class SOSApp extends StatelessWidget {
  const SOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SOS App',
      theme: appTheme,
      routes: appRoutes,
      initialRoute: '/',
    );
  }
}
```

### 3.4. Đăng ký Token sau khi Login

Cập nhật màn hình login (`lib/screens/login_screen.dart`):

```dart
// Sau khi login thành công, thêm:

// Lưu JWT token
final prefs = await SharedPreferences.getInstance();
await prefs.setString('jwt_token', token);

// Đăng ký FCM token với backend
await DeviceService.registerDevice(
  latitude: currentLatitude, // Nếu có
  longitude: currentLongitude, // Nếu có
);
```

### 3.5. Xóa Token khi Logout

Cập nhật màn hình logout:

```dart
// Trước khi logout, thêm:

// Xóa FCM token khỏi backend
await DeviceService.unregisterDevice();

// Xóa FCM token local
await FCMService.deleteToken();

// Xóa JWT token
final prefs = await SharedPreferences.getInstance();
await prefs.remove('jwt_token');
```

---

## 4. Xử lý Notification

### 4.1. Notification khi App Foreground

Khi app đang mở, bạn cần tự hiển thị notification. Cài thêm package:

```yaml
dependencies:
  flutter_local_notifications: ^16.3.0
```

Cập nhật `fcm_service.dart`:

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  /// Khởi tạo local notifications
  static Future<void> initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);
  }

  /// Hiển thị notification khi app foreground
  static Future<void> showNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'sos_emergency',
      'SOS Emergency',
      channelDescription: 'Notifications for SOS emergency cases',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      details,
    );
  }

  /// Setup notification handlers với hiển thị notification
  static void setupNotificationHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Hiển thị notification
      showNotification(message);
      
      // Xử lý data nếu cần
      if (message.data['type'] == 'SOS_CASE') {
        // TODO: Xử lý SOS case notification
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });
  }

  /// Xử lý khi tap vào notification
  static void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    
    if (data['type'] == 'SOS_CASE') {
      // Navigate đến màn hình SOS case detail
      // Navigator.pushNamed(context, '/sos-detail', arguments: {
      //   'caseId': data['caseId'],
      //   'caseCode': data['caseCode'],
      // });
    }
  }
}
```

### 4.2. Notification Data Structure

Khi có SOS case mới, notification sẽ có format:

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

### 4.3. Navigate dựa trên Notification Data

Cập nhật `main.dart` để navigate:

```dart
import 'package:flutter/material.dart';

// Trong setupNotificationHandlers hoặc checkInitialMessage:

void handleNotificationNavigation(Map<String, dynamic> data) {
  if (data['type'] == 'SOS_CASE') {
    // Sử dụng navigator key để navigate từ bất kỳ đâu
    navigatorKey.currentState?.pushNamed(
      '/sos-detail',
      arguments: {
        'caseId': data['caseId'],
        'caseCode': data['caseCode'],
      },
    );
  }
}
```

---

## 5. Test và Troubleshooting

### 5.1. Test đăng ký Device

```dart
// Test trong app
void testRegisterDevice() async {
  bool success = await DeviceService.registerDevice();
  print(success ? '✅ Success' : '❌ Failed');
}
```

### 5.2. Test từ Backend

```bash
cd z_Backend
node test-fcm.js YOUR_FCM_TOKEN
```

### 5.3. Test từ Firebase Console

1. Firebase Console → Cloud Messaging
2. Click "Send test message"
3. Nhập FCM token
4. Nhập title và body
5. Click "Test"

### 5.4. Troubleshooting

**Lỗi: "JWT token not found"**
- Đảm bảo user đã login trước khi đăng ký device
- Kiểm tra JWT token đã được lưu trong SharedPreferences

**Lỗi: "FCM token is null"**
- Kiểm tra quyền notification đã được cấp
- Xem log có error gì không
- Thử restart app

**Không nhận được notification:**
- Kiểm tra app có quyền notification không
- Test với token từ log console trước
- Kiểm tra notification channel đã được tạo chưa (Android 8.0+)

**Token không đăng ký được:**
- Kiểm tra backend đang chạy
- Kiểm tra baseUrl đúng chưa
- Xem response error từ backend

---

## 📚 Tài liệu tham khảo

- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- Backend FCM Guide: `z_Backend/README_FCM.md`
- Backend Setup: `z_Backend/config/FCM_SETUP_GUIDE.md`

---

## ✅ Checklist tích hợp

- [ ] Đã thêm Firebase dependencies
- [ ] Đã đặt `google-services.json` đúng vị trí
- [ ] Đã cấu hình build.gradle
- [ ] Đã tạo `DeviceService`
- [ ] Đã cập nhật `FCMService`
- [ ] Đã đăng ký token sau khi login
- [ ] Đã xóa token khi logout
- [ ] Đã setup notification handlers
- [ ] Đã test đăng ký device
- [ ] Đã test nhận notification

---

## 🎯 Flow hoàn chỉnh

1. **User mở app** → Firebase init → Lấy FCM token
2. **User login** → Lưu JWT token → Đăng ký FCM token với backend
3. **SOS case mới** → Backend gửi FCM notification
4. **User nhận notification** → Tap notification → Navigate đến screen tương ứng
5. **User logout** → Xóa FCM token khỏi backend

Happy coding! 🚀
