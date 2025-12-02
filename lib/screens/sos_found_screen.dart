import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

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
              title: const Text(
                'Tình nguyện viên đã hủy',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: const Text(
                'Tình nguyện viên đã hủy. Hệ thống đang tìm người khác hỗ trợ bạn...',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Đồng ý'),
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
              Navigator.pop(context); // Close dialog
              Navigator.popUntil(context, (route) => route.isFirst);
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
      // Get user's current position
      Position userPosition = await Geolocator.getCurrentPosition();

      // Get volunteer's position from caseData
      final volunteerLoc =
          _currentCaseData?['responderLocation']?['coordinates'];

      if (volunteerLoc != null &&
          volunteerLoc is List &&
          volunteerLoc.length >= 2) {
        final volunteerLat = volunteerLoc[1];
        final volunteerLng = volunteerLoc[0];

        // Calculate distance in meters
        double distanceInMeters = Geolocator.distanceBetween(
          userPosition.latitude,
          userPosition.longitude,
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
        final dt = DateTime.parse(acceptedAt);
        acceptedTime = '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
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
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
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
                              'Đã chấp nhận lúc $acceptedTime',
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

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
