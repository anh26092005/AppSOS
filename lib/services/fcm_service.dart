import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/navigation_service.dart';
import '../widgets/sos_alert_dialog.dart';
import '../widgets/sos_accepted_dialog.dart';

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
        // Cấu hình để hiện thông báo hệ thống ngay cả khi app đang foreground (iOS/Android 13+)
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        // Lấy token
        _fcmToken = await _messaging.getToken();

        if (kDebugMode) {
          print(
            '═══════════════════════════════════════════════════════════════',
          );
          print('✅ FCM Token obtained:');
          print(_fcmToken);
          print(
            '═══════════════════════════════════════════════════════════════',
          );
        }

        return _fcmToken;
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
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
        print(
          '═══════════════════════════════════════════════════════════════',
        );
        print('📨 Notification received (foreground):');
        print('Title: ${message.notification?.title}');
        print('Body: ${message.notification?.body}');
        print('Data: ${message.data}');
        print('Type: ${message.data['type']}');
        print('Context available: ${NavigationService.context != null}');
        print(
          '═══════════════════════════════════════════════════════════════',
        );
      }

      // Hiển thị SOS Alert Dialog nếu là tin nhắn SOS
      if (message.data['type'] == 'SOS_CASE') {
        final context = NavigationService.context;
        if (context != null) {
          try {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return SOSAlertDialog(
                  title: message.notification?.title ?? 'SOS Alert',
                  body: message.notification?.body ?? 'Có trường hợp khẩn cấp!',
                  data: message.data,
                  onAccept: () {
                    Navigator.of(context).pop(); // Đóng dialog
                    print('User accepted SOS case: ${message.data['caseId']}');
                  },
                  onDecline: () {
                    Navigator.of(context).pop(); // Đóng dialog
                  },
                );
              },
            );
            print('✅ SOS Alert Dialog shown');
          } catch (e) {
            print('❌ Error showing SOS Alert Dialog: $e');
          }
        } else {
          print('❌ Cannot show dialog: Context is null');
        }
      }

      // Hiển thị SOS Accepted Dialog nếu TNV chấp nhận case
      if (message.data['type'] == 'SOS_ACCEPTED') {
        final context = NavigationService.context;
        if (context != null) {
          try {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return SOSAcceptedDialog(
                  title: message.notification?.title ?? 'TNV đã nhận!',
                  body:
                      message.notification?.body ?? 'TNV đang đến hỗ trợ bạn.',
                  data: message.data,
                  onAction: () {
                    Navigator.of(context).pop(); // Đóng dialog
                    print(
                      'User view volunteer location: ${message.data['volunteerId']}',
                    );
                  },
                  onClose: () {
                    Navigator.of(context).pop(); // Đóng dialog
                  },
                );
              },
            );
            print('✅ SOS Accepted Dialog shown');
          } catch (e) {
            print('❌ Error showing SOS Accepted Dialog: $e');
          }
        } else {
          print('❌ Cannot show dialog: Context is null');
        }
      }
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
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();

    if (initialMessage != null) {
      if (kDebugMode) {
        print('📨 App opened from notification (terminated):');
        print('Data: ${initialMessage.data}');
      }

      // TODO: Navigate to specific screen based on notification data
    }
  }
}
