import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/navigation_service.dart';
import '../widgets/sos_alert_dialog.dart';
import '../screens/sos_notification_dialog.dart';
import '../widgets/sos_accepted_dialog.dart';
import '../services/api_service.dart';
import '../services/notification_sound_service.dart';
import '../providers/active_sos_provider.dart';
import 'package:vibration/vibration.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;

  // Stream controller for cancellation events
  static final _cancelController = StreamController<String>.broadcast();
  static Stream<String> get cancelStream => _cancelController.stream;

  /// Lấy FCM token
  static Future<String?> getFCMToken() async {
    try {
      // Yêu cầu quyền notification (không cho phép Firebase tự phát sound)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: false, // Tắt sound của Firebase, chỉ dùng custom sound
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Cấu hình để hiện thông báo hệ thống khi app đang foreground (iOS/Android 13+)
        // QUAN TRỌNG: Tắt sound để không phát âm thanh system, chỉ dùng custom sound
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: false, // Tắt âm thanh system để dùng custom sound
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
        // [FIX] Check if current user is the reporter - skip dialog if so
        final currentUser = await ApiService.getCachedUser();
        final currentUserId = currentUser?['id'] ?? currentUser?['_id'];
        final reporterId = message.data['reporterId'];

        print('🔍 SOS_CASE notification check:');
        print('  Current User ID: $currentUserId');
        print('  Reporter ID: $reporterId');

        // Skip dialog if user is the reporter (don't show TNV dialog to yourself)
        if (currentUserId != null &&
            reporterId != null &&
            currentUserId.toString() == reporterId.toString()) {
          print('🚫 Skipping SOS dialog - user is the reporter');
          return;
        }

        // Phát âm thanh thông báo
        NotificationSoundService.playNotificationSound();

        // [NEW] Rụng khi nhận SOS
        try {
          if (await Vibration.hasVibrator() ?? false) {
            // Rung mạnh: 500ms -> dừng 200ms -> 500ms
            Vibration.vibrate(
              pattern: [0, 500, 200, 500],
              intensities: [0, 255, 0, 255],
            );
          }
        } catch (e) {
          print('⚠️ Vibration error: $e');
        }

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
                            'SOS-${message.data['caseId'].toString().substring(0, 4)}',
                        emergencyType:
                            message.data['emergencyType'] ?? 'EMERGENCY',
                        distance: message.data['distance'] ?? 'Unknown',
                        reporterName: message.data['reporterName'],
                        manualAddress: message.data['manualAddress'],
                        reporterLatitude: message.data['latitude'] != null
                            ? double.tryParse(
                                message.data['latitude'].toString(),
                              )
                            : null,
                        reporterLongitude: message.data['longitude'] != null
                            ? double.tryParse(
                                message.data['longitude'].toString(),
                              )
                            : null,
                        onAccepted: (sosData) {
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
        // Phát âm thanh thông báo
        NotificationSoundService.playNotificationSound();

        final context = NavigationService.context;

        if (context != null) {
          try {
            final caseId = message.data['caseId'];

            // Broadcast cancellation event to close any open dialogs
            _cancelController.add(caseId.toString());

            final activeSosProvider = Provider.of<ActiveSosProvider>(
              context,
              listen: false,
            );

            // Check if this cancelled case is the one volunteer accepted
            // activeSosCase structure: { "case": { "_id": "...", ... }, ... }
            final currentCaseId =
                activeSosProvider.activeSosCase?['case']?['_id'];

            print(
              '🔍 Checking cancel match: Notif($caseId) vs Current($currentCaseId)',
            );

            if (currentCaseId == caseId) {
              print('🧹 Clearing active case from banner (cancelled by user)');
              await activeSosProvider.clearActiveCase();

              // Only show dialog if we were actually working on this case
              if (context.mounted) {
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
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/main',
                              (route) => false,
                            );
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
                print('✅ SOS Cancelled Dialog shown (for active case)');
              }
            } else {
              print('ℹ️ Ignored SOS_CANCELLED for non-active case: $caseId');
            }
          } catch (e) {
            print('❌ Error handling SOS cancel: $e');
          }
        } else {
          print('❌ Cannot show dialog: Context is null');
        }
      }

      // Xử lý khi SOS hết hạn (TNV timeout)
      if (message.data['type'] == 'SOS_EXPIRED') {
        // Phát âm thanh thông báo
        NotificationSoundService.playNotificationSound();

        final caseId = message.data['caseId'];

        // Broadcast expired event to close dialog
        _cancelController.add(caseId.toString());

        // Show snackbar
        final context = NavigationService.context;
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⏱️ Yêu cầu đã được chuyển sang tình nguyện viên khác',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );

          // Navigate về trang chủ sau khi snackbar hiện
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamedAndRemoveUntil('/main', (route) => false);
            }
          });
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
