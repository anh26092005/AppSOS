import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;

  /// Lấy FCM token
  static Future<String?> getFCMToken() async {
    try {
      // Yêu cầu quyền notification
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Lấy token
        _fcmToken = await _messaging.getToken();
        
        if (kDebugMode) {
          print('═══════════════════════════════════════════════════════════════');
          print('✅ FCM Token obtained:');
          print(_fcmToken);
          print('═══════════════════════════════════════════════════════════════');
        }
        
        return _fcmToken;
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        _fcmToken = await _messaging.getToken();
        
        if (kDebugMode) {
          print('✅ FCM Token (provisional): $_fcmToken');
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

  /// Lắng nghe khi token refresh
  static void setupTokenRefreshListener(Function(String) onTokenRefresh) {
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      if (kDebugMode) {
        print('🔄 FCM Token refreshed: $newToken');
      }
      onTokenRefresh(newToken);
    });
  }

  /// Lấy token hiện tại (nếu đã có)
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
    });

    // Xử lý khi user tap vào notification (app đang background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('📨 Notification tapped (background):');
        print('Data: ${message.data}');
      }
      
      // TODO: Navigate to specific screen based on notification data
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
      
      // TODO: Navigate to specific screen based on notification data
    }
  }
}

