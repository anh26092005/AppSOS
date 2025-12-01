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

  bool _isLoading = true; // Thêm trạng thái loading để tránh flash màn hình

  @override
  void initState() {
    super.initState();
    _checkActiveSos();
  }

  Future<void> _checkActiveSos() async {
    final activeCase = await ApiService.getActiveSosCase();

    if (activeCase != null && mounted) {
      final status = activeCase['status'];
      final userRole = activeCase['userRole']; // Lấy role từ backend

      // Delay nhẹ để đảm bảo context sẵn sàng
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      if (userRole == 'REPORTER') {
        // Logic cho người báo tin
        if (status == 'SEARCHING') {
          Navigator.pushNamed(
            context,
            '/sos-searching',
            arguments: {'caseId': activeCase['_id'], 'caseData': activeCase},
          );
        } else if (status == 'ACCEPTED' || status == 'IN_PROGRESS') {
          Navigator.pushNamed(
            context,
            '/sos-found',
            arguments: {'caseId': activeCase['_id'], 'caseData': activeCase},
          );
        }
      } else if (userRole == 'VOLUNTEER') {
        // Logic cho tình nguyện viên
        if (status == 'ACCEPTED' || status == 'IN_PROGRESS') {
          // SosAcceptedScreen cần cấu trúc { 'case': ... }
          // Backend trả về activeCase đã populate đầy đủ
          Navigator.pushNamed(
            context,
            '/sos-accepted',
            arguments: {'case': activeCase, 'directionsUrl': null},
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false; // Tắt loading sau khi check xong
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hiển thị màn hình loading nếu đang check SOS
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

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
