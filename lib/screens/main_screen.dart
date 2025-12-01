import 'package:flutter/material.dart';
import 'home_page_new.dart';
import 'account_page.dart';
import 'sos_emergency_screen.dart';
import 'activity_history_screen.dart';
import '../widgets/floating_navbar.dart';
import '../services/api_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePageNew(),
    const ActivityHistoryScreen(),
    const SosEmergencyScreen(), // SOS is now index 2
    const AccountPage(), // Profile is now index 3
  ];

  @override
  void initState() {
    super.initState();
    _checkActiveSos();
  }

  Future<void> _checkActiveSos() async {
    final activeCase = await ApiService.getActiveSosCase();

    if (activeCase != null && mounted) {
      final status = activeCase['status'];
      final caseId = activeCase['_id'];

      // Delay nhẹ để UI render xong
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      if (status == 'SEARCHING') {
        Navigator.pushNamed(
          context,
          '/sos-searching',
          arguments: {'caseId': caseId, 'caseData': activeCase},
        );
      } else if (status == 'ACCEPTED' || status == 'IN_PROGRESS') {
        Navigator.pushNamed(
          context,
          '/sos-accepted',
          arguments: {'case': activeCase, 'directionsUrl': null},
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
            onActivityPressed: () {
              setState(() {
                _selectedIndex = 1;
              });
            },
            onSOSPressed: () {
              setState(() {
                _selectedIndex = 2;
              });
            },
            onProfilePressed: () {
              setState(() {
                _selectedIndex = 3;
              });
            },
          ),
        ],
      ),
    );
  }
}
