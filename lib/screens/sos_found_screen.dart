import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/active_sos_provider.dart';

class SosFoundScreen extends StatefulWidget {
  final String caseId;
  final Map<String, dynamic>? caseData;

  const SosFoundScreen({super.key, required this.caseId, this.caseData});

  @override
  State<SosFoundScreen> createState() => _SosFoundScreenState();
}

class _SosFoundScreenState extends State<SosFoundScreen> {
  Timer? _pollingTimer;
  Map<String, dynamic>? _currentCaseData;
  bool _isLoading = true;
  bool _isCancelling = false;
  double? _distanceInKm;
  String? _estimatedTime;

  @override
  void initState() {
    super.initState();
    _currentCaseData = widget.caseData;

    // If we don't have initial data, fetch it
    if (_currentCaseData == null) {
      _fetchCaseDetails();
    } else {
      _isLoading = false;
    }

    // Start polling every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchCaseDetails();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCaseDetails() async {
    try {
      final response = await ApiService.getSosCaseDetails(widget.caseId);
      final caseData = response['data']['case'];

      if (!mounted) return;

      setState(() {
        _currentCaseData = caseData;
        _isLoading = false;
      });

      // Calculate distance
      _calculateDistance();

      final status = caseData['status'];

      // Check if volunteer cancelled
      if (status == 'SEARCHING') {
        _pollingTimer?.cancel();
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Tình nguyện viên đã hủy',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: const Text(
                'Tình nguyện viên đã hủy yêu cầu. Bạn có muốn tiếp tục tìm kiếm tình nguyện viên khác không?',
              ),
              actions: [
                // Nút "Về trang chủ"
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushNamedAndRemoveUntil('/main', (route) => false);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300, width: 2),
                  ),
                  child: const Text('Về trang chủ'),
                ),
                // Nút "Tìm TNV khác"
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to searching screen
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Tìm TNV khác'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }
      }

      // Check if completed
      if (status == 'RESOLVED') {
        _pollingTimer?.cancel();
        if (mounted) {
          _showCompletionDialog();
        }
      }
    } catch (e) {
      print('Error fetching case details: $e');
    }
  }

  void _showCompletionDialog() {
    // Clear banner FIRST
    if (mounted) {
      context.read<ActiveSosProvider>().clearActiveCase();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            const Text(
              'Ứng cứu hoàn thành',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text('Ứng cứu đã hoàn thành! .'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/main', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Về trang chủ'),
          ),
        ],
      ),
    );
  }

  Future<void> _calculateDistance() async {
    try {
      // Get reporter's position from caseData (static at time of SOS creation)
      final reporterLoc = _currentCaseData?['location']?['coordinates'];

      // Get volunteer's position from caseData (static at time of accept)
      final volunteerLoc =
          _currentCaseData?['responderLocation']?['coordinates'];

      if (reporterLoc != null &&
          reporterLoc is List &&
          reporterLoc.length >= 2 &&
          volunteerLoc != null &&
          volunteerLoc is List &&
          volunteerLoc.length >= 2) {
        final reporterLat = reporterLoc[1];
        final reporterLng = reporterLoc[0];
        final volunteerLat = volunteerLoc[1];
        final volunteerLng = volunteerLoc[0];

        // Calculate distance in meters (between static positions)
        double distanceInMeters = Geolocator.distanceBetween(
          reporterLat,
          reporterLng,
          volunteerLat,
          volunteerLng,
        );

        // Convert to kilometers
        double distanceKm = distanceInMeters / 1000;

        // Calculate ETA (assuming 40 km/h average speed)
        double timeInHours = distanceKm / 40;
        int timeInMinutes = (timeInHours * 60).round();

        if (mounted) {
          setState(() {
            _distanceInKm = distanceKm;
            _estimatedTime = timeInMinutes > 0
                ? '~$timeInMinutes phút'
                : 'Đang đến';
          });
        }
      }
    } catch (e) {
      print('Error calculating distance: $e');
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể gọi điện thoại'),
            backgroundColor: Colors.red,
          ),
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
        content: const Text(
          'Bạn có chắc chắn muốn hủy yêu cầu SOS này?\n\nTình nguyện viên đang đến hỗ trợ bạn.',
        ),
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

    // Cancel polling timer FIRST
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

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hủy yêu cầu SOS'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Clear active case in provider
      if (mounted) {
        context.read<ActiveSosProvider>().clearActiveCase();
      }

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      // Navigate to main screen
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
      _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        _fetchCaseDetails();
      });

      final errorMessage = e.toString();

      // Check for specific error messages
      if (errorMessage.contains('Cannot cancel SOS case in current status')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không thể hủy yêu cầu lúc này. Tình nguyện viên có thể đã hoàn thành hoặc đang xử lý.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      } else if (errorMessage.contains('401') ||
          errorMessage.contains('Unauthorized')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.'),
            backgroundColor: Colors.orange,
          ),
        );
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
    if (_isLoading || _currentCaseData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Thông tin tình nguyện viên'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final responderInfo = _currentCaseData!['responderInfo'] ?? {};
    final volunteerName = responderInfo['volunteerName'] ?? 'Tình nguyện viên';
    final volunteerPhone = responderInfo['volunteerPhone'];
    final acceptedAt = responderInfo['acceptedAt'];

    // Format time
    String acceptedTime = '';
    if (acceptedAt != null) {
      try {
        final dt = DateTime.parse(acceptedAt).toLocal(); // Convert UTC to local
        acceptedTime =
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        print('Error parsing acceptedAt: $e');
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Đã tìm thấy hỗ trợ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: () async {
              // Clear active case first
              await context.read<ActiveSosProvider>().clearActiveCase();

              if (!mounted) return;

              // Navigate to main screen
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/main', (route) => false);
            },
            tooltip: 'Về trang chủ',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.shade100,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 60,
                    color: Colors.green.shade700,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              const Text(
                'Đã tìm thấy tình nguyện viên!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Tình nguyện viên đang trên đường đến bạn',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Volunteer info card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade300, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar and name
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.green.shade400,
                                Colors.green.shade700,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                volunteerName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Tình nguyện viên',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Phone number
                    if (volunteerPhone != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.phone,
                              color: Colors.green.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                volunteerPhone,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _makePhoneCall(volunteerPhone),
                              icon: Icon(
                                Icons.call,
                                color: Colors.green.shade700,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.green.shade100,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Accepted time
                    if (acceptedTime.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.green.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Đã chấp nhận lúc ${acceptedTime.isNotEmpty ? acceptedTime : "N/A"}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Distance and ETA card
              if (_distanceInKm != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue.shade50, Colors.blue.shade100],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade300, width: 2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: Colors.blue.shade700,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cách bạn: ${_distanceInKm!.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (_estimatedTime != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    color: Colors.grey.shade600,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Dự kiến: $_estimatedTime',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              // Call button
              if (volunteerPhone != null)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _makePhoneCall(volunteerPhone),
                    icon: const Icon(Icons.call, size: 24),
                    label: const Text(
                      'Gọi điện cho tình nguyện viên',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Cancel button - only show if case is still ACCEPTED (not RESOLVED yet)
              if (_currentCaseData?['status'] == 'ACCEPTED')
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isCancelling ? null : _cancelSos,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isCancelling
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.red,
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
