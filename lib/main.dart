import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'router_theme/routes.dart';
import 'router_theme/theme.dart';
import 'services/fcm_service.dart';

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
