import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'router_theme/routes.dart';
import 'router_theme/theme.dart';
import 'services/fcm_service.dart';
import 'services/api_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await Firebase.initializeApp();

  // Lấy FCM token và đăng ký với backend
  final token = await FCMService.getFCMToken();
  if (token != null) {
    _registerTokenWithBackend(token);
  }

  // Setup notification handlers
  FCMService.setupNotificationHandlers();
  FCMService.checkInitialMessage();

  // Setup token refresh listener
  FCMService.setupTokenRefreshListener((newToken) {
    print('🔄 Token mới: $newToken');
    _registerTokenWithBackend(newToken);
  });

  runApp(const SOSApp());
}

// Helper function để đăng ký token với backend
Future<void> _registerTokenWithBackend(String token) async {
  try {
    // Chờ một chút để đảm bảo user đã đăng nhập
    await Future.delayed(const Duration(seconds: 2));

    // Kiểm tra xem đã đăng nhập chưa
    final hasSession = await ApiService.hasActiveSession();
    if (!hasSession) {
      print('⏳ Chưa đăng nhập, sẽ đăng ký token sau khi đăng nhập');
      return;
    }

    await ApiService.registerDeviceToken(token);
    print('✅ Đã đăng ký FCM token với backend');
  } catch (e) {
    print('❌ Lỗi đăng ký FCM token: $e');
    // Không throw error để không crash app
  }
}

class SOSApp extends StatelessWidget {
  const SOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SOS App',
      theme: appTheme,
      initialRoute: '/',
      routes: {'/': (_) => const _AppEntry(), ...appRoutes},
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry({super.key});

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  late Future<bool> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = ApiService.hasActiveSession();
    _registerTokenIfLoggedIn();
  }

  // Đăng ký FCM token nếu đã đăng nhập
  Future<void> _registerTokenIfLoggedIn() async {
    final hasSession = await ApiService.hasActiveSession();
    if (hasSession) {
      final token = FCMService.currentToken;
      if (token != null) {
        _registerTokenWithBackend(token);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final hasSession = snapshot.data ?? false;
        return hasSession ? const MainScreen() : const WelcomeSOSScreen();
      },
    );
  }
}
