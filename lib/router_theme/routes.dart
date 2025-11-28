import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/main_screen.dart';
import '../screens/home_screen.dart';
import '../screens/sos_emergency_screen.dart';
import '../screens/sos_found_screen.dart';
import '../screens/sos_searching_screen.dart';
import '../screens/account_screen.dart';
import '../screens/tnv_screen.dart';
import '../screens/info_tnv_screen.dart';
import '../screens/volunteer_dashboard_screen.dart';
import '../screens/permission_test_screen.dart';
import '../screens/fcm_token_screen.dart';
import '../screens/sos_accepted_screen.dart';
import '../screens/volunteer_registration_screen.dart';
import '../screens/settings_page.dart';
import '../screens/volunteer_profile_screen.dart';

Map<String, WidgetBuilder> appRoutes = {
  '/login': (_) => const LoginScreen(),
  '/signup': (_) => const SignupScreen(),
  '/main': (_) => const MainScreen(),
  '/home': (_) => const HomeScreen(),
  '/sos-emergency': (_) => const SosEmergencyScreen(),
  '/sos-found': (context) {
    final args =
        (ModalRoute.of(context)!.settings.arguments ?? {})
            as Map<String, dynamic>;
    return SosFoundScreen(
      caseId: args['caseId'] as String? ?? '',
      caseData: args['caseData'] as Map<String, dynamic>?,
    );
  },
  '/sos-searching': (context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return SosSearchingScreen(
      caseId: args['caseId'] as String,
      caseData: args['caseData'] as Map<String, dynamic>?,
    );
  },
  '/account': (_) => const AccountScreen(),
  '/tnv': (_) => const TnvScreen(),
  '/info-tnv': (context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    return InfoTnvScreen(tnvData: args as Map<String, dynamic>?);
  },
  '/volunteer-dashboard': (_) => const VolunteerDashboardScreen(),
  '/permission-test': (_) => const PermissionTestScreen(),
  '/fcm-token': (_) => const FCMTokenScreen(),
  '/sos-accepted': (context) {
    final sosData =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return SosAcceptedScreen(sosData: sosData);
  },
  '/volunteer-registration': (_) => const VolunteerRegistrationScreen(),
  '/volunteer-profile': (context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return VolunteerProfileScreen(volunteerData: args);
  },
  '/settings': (_) => const SettingsPage(),
};
