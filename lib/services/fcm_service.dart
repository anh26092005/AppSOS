import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/navigation_service.dart';
import '../widgets/sos_alert_dialog.dart';
import '../screens/sos_notification_dialog.dart';
import '../widgets/sos_accepted_dialog.dart';
import '../services/api_service.dart';
import '../providers/active_sos_provider.dart';

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
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
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
                  caseId: message.data['caseId'],
                  onAccept: () {
                    Navigator.of(context).pop(); // Đóng alert dialog
                    print('User accepted SOS alert: ${message.data['caseId']}');

                    // Mở dialog chấp nhận chi tiết
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => SosNotificationDialog(
                        caseId: message.data['caseId'],
                        caseCode:
                            'SOS-${message.data['caseId'].toString().substring(0, 4)}', // Fallback code
                        emergencyType:
                            message.data['emergencyType'] ?? 'EMERGENCY',
                        distance: message.data['distance'] ?? 'Unknown',
                        onAccepted: (sosData) {
                          // Save to active SOS provider
                          context.read<ActiveSosProvider>().setActiveCase(
                            sosData,
                          );
                        },
                      ),
                    );
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

      // ❌ DISABLED: Dialog này được thay thế bằng SosFoundScreen (user tự động navigate qua polling)
      // Hiển thị SOS Accepted Dialog nếu TNV chấp nhận case
      if (false && message.data['type'] == 'SOS_ACCEPTED') {
        ApiService.getCachedUser().then((user) {
          print('🔍 Checking user role for SOS_ACCEPTED dialog');
          print('User: $user');
          print('Roles: ${user?['roles']}');

          // Check if user has volunteer role (TNV_CN or VOLUNTEER)
          if (user != null && user['roles'] != null) {
            final roles = user['roles'] as List;
            if (roles.contains('TNV_CN') || roles.contains('VOLUNTEER')) {
              print('🚫 Skipping SOS Accepted Dialog for Volunteer');
              return;
            }
          }

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
                        message.notification?.body ??
                        'TNV đang đến hỗ trợ bạn.',
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
        });
      }

      // Hiển thị Alert khi SOS bị hủy
      if (message.data['type'] == 'SOS_CANCELLED') {
        final context = NavigationService.context;

        // Clear active SOS banner if this volunteer had accepted it
        if (context != null) {
          try {
            final caseId = message.data['caseId'];
            final activeSosProvider = Provider.of<ActiveSosProvider>(
              context,
              listen: false,
            );

            // Check if this cancelled case is the one volunteer accepted
            if (activeSosProvider.activeSosCase?['_id'] == caseId) {
              print('🧹 Clearing active case from banner (cancelled by user)');
              await activeSosProvider.clearActiveCase();
            }
          } catch (e) {
            print('❌ Error clearing active case: $e');
          }
        }

        if (context != null) {
          try {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.orange, size: 28),
                      SizedBox(width: 12),
                      Text(
                        message.notification?.title ?? 'SOS đã bị hủy',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    message.notification?.body ??
                        'Người dùng đã hủy yêu cầu SOS',
                    style: TextStyle(fontSize: 16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Đóng dialog
                        // Navigate về trang chủ
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/main', (route) => false);
                      },
                      child: Text(
                        'Đóng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
            print('✅ SOS Cancelled Dialog shown');
          } catch (e) {
            print('❌ Error showing SOS Cancelled Dialog: $e');
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
