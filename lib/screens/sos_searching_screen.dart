import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'sos_found_screen.dart';

class SosSearchingScreen extends StatefulWidget {
  final String caseId;
  final Map<String, dynamic>? caseData;

  const SosSearchingScreen({super.key, required this.caseId, this.caseData});

  @override
  State<SosSearchingScreen> createState() => _SosSearchingScreenState();
}

class _SosSearchingScreenState extends State<SosSearchingScreen>
    with SingleTickerProviderStateMixin {
  Timer? _pollingTimer;
  bool _isCancelling = false;
  late AnimationController _animationController;
  Map<String, dynamic>? _currentCaseData;

  @override
  void initState() {
    super.initState();
    _currentCaseData = widget.caseData;

    // Setup animation controller for radar effect
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Start polling every 3 seconds
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startPolling() {
    // Poll immediately
    _checkCaseStatus();

    // Then poll every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkCaseStatus();
    });
  }

  Future<void> _checkCaseStatus() async {
    try {
      final response = await ApiService.getSosCaseDetails(widget.caseId);
      final caseData = response['data']['case'];

      if (!mounted) return;

      setState(() {
        _currentCaseData = caseData;
      });

      final status = caseData['status'];

      if (status == 'ACCEPTED') {
        // Volunteer đã chấp nhận, navigate to found screen
        _pollingTimer?.cancel();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SosFoundScreen(caseId: widget.caseId, caseData: caseData),
            ),
          );
        }
      } else if (status == 'CANCELLED') {
        // Case đã bị hủy
        _pollingTimer?.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Yêu cầu SOS đã bị hủy'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context);
        }
      }
      // Nếu status == 'SEARCHING', tiếp tục polling
    } catch (e) {
      print('Error checking case status: $e');
      // Vẫn tiếp tục polling nếu có lỗi
    }
  }

  Future<void> _cancelSos() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hủy yêu cầu SOS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Bạn có chắc chắn muốn hủy yêu cầu SOS này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hủy yêu cầu'),
          ),
        ],
      ),
    );

    if (shouldCancel != true) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      await ApiService.cancelSosCase(widget.caseId, 'Người dùng hủy yêu cầu');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hủy yêu cầu SOS'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCancelling = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi hủy: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final emergencyType = _currentCaseData?['emergencyType'] ?? 'MEDICAL';
    final description = _currentCaseData?['description'] ?? '';
    final createdAt = _currentCaseData?['createdAt'];

    String emergencyTypeVi = '';
    IconData emergencyIcon = Icons.local_hospital;
    Color emergencyColor = Colors.red;

    switch (emergencyType) {
      case 'MEDICAL':
        emergencyTypeVi = 'Y tế';
        emergencyIcon = Icons.local_hospital;
        emergencyColor = Colors.red;
        break;
      case 'FIRE':
        emergencyTypeVi = 'Cháy nổ';
        emergencyIcon = Icons.local_fire_department;
        emergencyColor = Colors.deepOrange;
        break;
      case 'ACCIDENT':
        emergencyTypeVi = 'Tai nạn';
        emergencyIcon = Icons.car_crash;
        emergencyColor = Colors.orange;
        break;
      case 'CRIME':
        emergencyTypeVi = 'Trộm cắp';
        emergencyIcon = Icons.security;
        emergencyColor = Colors.purple;
        break;
      case 'NATURAL_DISASTER':
        emergencyTypeVi = 'Thiên tai';
        emergencyIcon = Icons.warning;
        emergencyColor = Colors.brown;
        break;
      default:
        emergencyTypeVi = 'Khác';
        emergencyIcon = Icons.warning;
        emergencyColor = Colors.grey;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Đang tìm kiếm hỗ trợ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),

              // Radar animation
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer rings
                      for (int i = 3; i > 0; i--)
                        Opacity(
                          opacity:
                              (_animationController.value > (i - 1) / 3 &&
                                  _animationController.value < i / 3)
                              ? 1 -
                                    ((_animationController.value -
                                            (i - 1) / 3) *
                                        3)
                              : 0,
                          child: Container(
                            width: 80.0 * i,
                            height: 80.0 * i,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.orange,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      // Center icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.orange.shade100,
                        ),
                        child: Icon(
                          Icons.search,
                          size: 40,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Status text
              const Text(
                'Đang tìm kiếm tình nguyện viên',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Vui lòng đợi trong giây lát...',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Emergency info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: emergencyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: emergencyColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(emergencyIcon, color: emergencyColor, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Loại khẩn cấp: $emergencyTypeVi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: emergencyColor,
                          ),
                        ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Mô tả:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                    if (createdAt != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Thời gian gửi: ${DateTime.parse(createdAt).hour}:${DateTime.parse(createdAt).minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Spacer(),

              // Cancel button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCancelling ? null : _cancelSos,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCancelling
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Hủy yêu cầu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
