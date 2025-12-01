import 'package:flutter/material.dart';
import 'home_page_new.dart';
import 'blog_page.dart';
import 'account_page.dart';
import 'sos_emergency_screen.dart';
import '../widgets/floating_navbar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePageNew(),
    const BlogPage(),
    const AccountPage(),
    const SosEmergencyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Nội dung chính
          // Nội dung chính
          Positioned.fill(child: _pages[_selectedIndex]),
          // Floating navbar
          FloatingNavbar(
            selectedIndex: _selectedIndex,
            onHomePressed: () {
              setState(() {
                _selectedIndex = 0;
              });
            },
            onSOSPressed: () {
              setState(() {
                _selectedIndex = 3;
              });
            },
            onProfilePressed: () {
              setState(() {
                _selectedIndex = 2;
              });
            },
          ),
        ],
      ),
    );
  }
}
