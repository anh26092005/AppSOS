import 'package:flutter/material.dart';
import '../screens/welcome_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/main_screen.dart';
import '../screens/sos_screen.dart';
import '../screens/account_screen.dart';

Map<String, WidgetBuilder> appRoutes = {
  '/': (_) => const WelcomeScreen(),
  '/login': (_) => const LoginScreen(),
  '/signup': (_) => const SignupScreen(),
  '/main': (_) => const MainScreen(),
  '/sos': (_) => const SosScreen(),
  '/account': (_) => const AccountScreen(),
};
