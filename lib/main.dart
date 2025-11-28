import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'router_theme/routes.dart';
import 'router_theme/theme.dart';
import 'services/fcm_service.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'utils/navigation_service.dart';

import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await Firebase.initializeApp();

  // Lấy FCM token và in ra console
  await FCMService.getFCMToken();

  // Setup notification handlers
  FCMService.setupNotificationHandlers();
  FCMService.checkInitialMessage();

  // Setup token refresh listener
  FCMService.setupTokenRefreshListener((newToken) {
    print('🔄 Token mới: $newToken');
    // TODO: Gửi token mới lên backend
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const SOSApp(),
    ),
  );
}

class SOSApp extends StatelessWidget {
  const SOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: NavigationService.navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'SOS App',
          theme: appTheme,
          darkTheme: appThemeDark,
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          initialRoute: '/',
          routes: {'/': (_) => const _AppEntry(), ...appRoutes},
        );
      },
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

  Future<void> _registerTokenWithBackend(String token) async {
    try {
      await ApiService.registerDeviceToken(token);
      print('✅ Device token registered with backend');
    } catch (e) {
      print('❌ Failed to register device token: $e');
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
        return hasSession ? const MainScreen() : const LoginScreen();
      },
    );
  }
}
