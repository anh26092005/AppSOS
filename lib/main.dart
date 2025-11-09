import 'package:flutter/material.dart';
import 'router_theme/routes.dart';
import 'router_theme/theme.dart';

void main() => runApp(const SOSApp());

class SOSApp extends StatelessWidget {
  const SOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SOS App',
      theme: appTheme,
      routes: appRoutes,
      initialRoute: '/login',
    );
  }
}
