import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'router_theme/routes.dart';
import 'router_theme/theme.dart';
import 'services/fcm_service.dart';
import 'services/api_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_screen.dart';
import 'utils/navigation_service.dart';

// ... (giữ nguyên imports khác)

class SOSApp extends StatelessWidget {
  const SOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey, // Thêm dòng này
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
