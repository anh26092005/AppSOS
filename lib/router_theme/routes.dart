import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/main_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/signup': (_) => const SignupScreen(),
  '/login': (_) => const LoginScreen(),
  '/main': (_) => const MainScreen(),
};
