import 'package:flutter/material.dart';
import '../screens/welcome_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/main_screen.dart';
import '../screens/sos_screen.dart';
import '../screens/sos_found_screen.dart';
import '../screens/account_screen.dart';
import '../screens/tnv_screen.dart';
import '../screens/info_tnv_screen.dart';
import '../screens/volunteer_dashboard_screen.dart';

Map<String, WidgetBuilder> appRoutes = {
  '/': (_) => const WelcomeSOSScreen(),
  '/login': (_) => const LoginScreen(),
  '/signup': (_) => const SignupScreen(),
  '/main': (_) => const MainScreen(),
  '/sos': (_) => const SosScreen(),
  '/sos-found': (_) => const SosFoundScreen(),
  '/account': (_) => const AccountScreen(),
  '/tnv': (_) => const TnvScreen(),
  '/info-tnv': (context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    return InfoTnvScreen(tnvData: args as Map<String, dynamic>?);
  },
  '/volunteer-dashboard': (_) => const VolunteerDashboardScreen(),
};
