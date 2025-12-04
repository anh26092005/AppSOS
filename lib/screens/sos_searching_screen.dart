import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/active_sos_provider.dart';
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
      print('📡 Polling - Case status: $status');

      if (status == 'ACCEPTED') {
        // Volunteer đã chấp nhận, navigate to found screen
        print('✅ Status ACCEPTED - Navigating to SosFoundScreen');
        print('Case data: $caseData');
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
        print('⚠️ Status CANCELLED');
        _pollingTimer?.cancel();

        if (mounted) {
          // Check if auto-cancelled due to timeout
          final isAutoCancel =
              caseData['meta']?['autoCancelledDueToTimeout'] == true;

          if (isAutoCancel) {
            _showEmergencyNumbersDialog(caseData['emergencyType']);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Yêu cầu SOS đã bị hủy'),
                backgroundColor: Colors.orange,
              ),
            );
            Navigator.pop(context);
          }
        }
      }
      // Nếu status == 'SEARCHING', tiếp tục polling
    } catch (e) {
      print('❌ Error checking case status: $e');
      // Vẫn tiếp tục polling nếu có lỗi
    }
  }

  void _showEmergencyNumbersDialog(String? emergencyType) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Không tìm thấy TNV',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Rất tiếc, không có tình nguyện viên nào trong khu vực của bạn lúc này.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Vui lòng liên hệ khẩn cấp:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildEmergencyButton(
                number: '113',
                label: 'Công An / Cảnh Sát',
                color: Colors.blue,
                icon: Icons.local_police,
                isHighlighted: emergencyType == 'CRIME',
              ),
              const SizedBox(height: 8),
              _buildEmergencyButton(
                number: '114',
                label: 'Cứu Hỏa / Cứu Nạn',
                color: Colors.red,
                icon: Icons.local_fire_department,
                isHighlighted: emergencyType == 'FIRE',
              ),
              const SizedBox(height: 8),
              _buildEmergencyButton(
                number: '115',
                label: 'Cấp Cứu Y Tế',
                color: Colors.teal,
                icon: Icons.medical_services,
                isHighlighted:
                    emergencyType == 'MEDICAL' || emergencyType == 'ACCIDENT',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Clear active SOS case from provider first
                await context.read<ActiveSosProvider>().clearActiveCase();

                if (!mounted) return;

                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/main', (route) => false);
              },
              child: const Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyButton({
    required String number,
    required String label,
    required Color color,
    required IconData icon,
    bool isHighlighted = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _makePhoneCall(number),
        style: ElevatedButton.styleFrom(
          backgroundColor: isHighlighted ? color : Colors.white,
          foregroundColor: isHighlighted ? Colors.white : color,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          side: BorderSide(color: color, width: 2),
          elevation: isHighlighted ? 4 : 0,
        ),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    number,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isHighlighted ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.call),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch $launchUri';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể gọi số $phoneNumber: $e')),
        );
      }
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

    // Cancel polling timer FIRST before making any changes
    _pollingTimer?.cancel();

    setState(() {
      _isCancelling = true;
    });

    try {
      print('🔄 Cancelling SOS case: ${widget.caseId}');
      final response = await ApiService.cancelSosCase(
        widget.caseId,
        'Người dùng hủy yêu cầu',
      );

      print('✅ Cancel response: $response');

      if (!mounted) return;

      // Clear active case in provider
      context.read<ActiveSosProvider>().clearActiveCase();

      // Show success message before navigating
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hủy yêu cầu SOS'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Use a short delay to ensure snackbar is visible
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      print('🔄 Navigating to main screen after cancel');
      // Use Navigator.of(context) with rootNavigator to ensure proper navigation
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamedAndRemoveUntil('/main', (route) => false);
    } catch (e) {
      print('❌ Error cancelling SOS: $e');
      if (!mounted) return;

      setState(() {
        _isCancelling = false;
      });

      // Restart polling if cancel failed
      _startPolling();

      // Check if error is 401 Unauthorized
      final errorMessage = e.toString();
      if (errorMessage.contains('401') ||
          errorMessage.contains('Unauthorized')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.'),
            backgroundColor: Colors.orange,
          ),
        );
        // Navigate to login instead of just popping
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi hủy: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                  color: emergencyColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: emergencyColor.withValues(alpha: 0.3),
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
                        'Thời gian gửi: ${DateTime.parse(createdAt).toLocal().hour.toString().padLeft(2, '0')}:${DateTime.parse(createdAt).toLocal().minute.toString().padLeft(2, '0')}',
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
