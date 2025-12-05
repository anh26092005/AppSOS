import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';
import '../utils/navigation_service.dart';

class SOSAlertDialog extends StatefulWidget {
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final VoidCallback onAccept;
  final String caseId;

  const SOSAlertDialog({
    super.key,
    required this.title,
    required this.body,
    required this.data,
    required this.onAccept,
    required this.caseId,
  });

  @override
  State<SOSAlertDialog> createState() => _SOSAlertDialogState();
}

class _SOSAlertDialogState extends State<SOSAlertDialog> {
  StreamSubscription? _cancelSubscription;
  bool _isDismissed = false;
  String? _calculatedDistance; // [NEW] Real-time distance

  @override
  void initState() {
    super.initState();
    _calculateRealDistance(); // [NEW] Calculate real distance on init

    // Listen for cancellation events
    _cancelSubscription = FCMService.cancelStream.listen((cancelledCaseId) {
      if (cancelledCaseId == widget.caseId && !_isDismissed) {
        print('🔔 Dialog received cancel event for case ${widget.caseId}');
        if (mounted) {
          // Check if this route is actually the current one before popping
          final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
          if (isCurrent && Navigator.of(context).canPop()) {
            _isDismissed = true;
            Navigator.of(context).pop(); // Close the dialog

            // Show cancellation snackbar/dialog
            // Use a slight delay to ensure context is valid or use global key if needed
            Future.delayed(const Duration(milliseconds: 100), () {
              if (NavigationService.context != null) {
                ScaffoldMessenger.of(NavigationService.context!).showSnackBar(
                  const SnackBar(
                    content: Text('Đã hủy yêu cầu'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            });
          }
        }
      }
    });
  }

  // [NEW] Calculate real distance from TNV GPS to reporter
  Future<void> _calculateRealDistance() async {
    try {
      // Get reporter coordinates from FCM data
      final reporterLat = widget.data['latitude'];
      final reporterLng = widget.data['longitude'];

      if (reporterLat == null || reporterLng == null) {
        print('⚠️ Reporter coordinates not in notification data');
        setState(() {
          _calculatedDistance =
              widget.data['distance']; // Fallback to backend distance
        });
        return;
      }

      // Get TNV current GPS location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Calculate distance
      final distanceMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        double.parse(reporterLat.toString()),
        double.parse(reporterLng.toString()),
      );

      final distanceKm = distanceMeters / 1000;

      setState(() {
        _calculatedDistance = distanceKm.toStringAsFixed(1);
      });

      print('📏 Calculated real distance: ${distanceKm.toStringAsFixed(1)}km');
      print('   TNV: [${position.latitude}, ${position.longitude}]');
      print('   Reporter: [$reporterLat, $reporterLng]');
    } catch (e) {
      print('❌ Error calculating distance: $e');
      setState(() {
        _calculatedDistance = widget.data['distance']; // Fallback
      });
    }
  }

  @override
  void dispose() {
    _cancelSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleDismiss(BuildContext context) async {
    if (_isDismissed) return;

    // Show confirmation dialog
    final shouldDecline = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Hủy yêu cầu?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          'Yêu cầu này sẽ được chuyển đến tình nguyện viên khác. '
          'Bạn có chắc chắn muốn hủy?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Đóng',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Hủy yêu cầu',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );

    // If user didn't confirm, just return (do nothing)
    if (shouldDecline != true) return;

    _isDismissed = true;

    // User confirmed - decline the case and forward to next volunteer
    try {
      await ApiService.declineSosCase(
        widget.caseId,
        'Không thể hỗ trợ lúc này', // Default reason
      );
      print('✅ Case ${widget.caseId} declined, forwarded to next volunteer');
    } catch (e) {
      print('❌ Error declining case: $e');

      // If already declined, just close silently
      final errorMessage = e.toString();
      if (errorMessage.contains('already declined')) {
        print('ℹ️ Case already declined, closing dialog silently');
        if (!mounted) return;
        Navigator.of(context).pop();
        return;
      }

      // Show error to user for other errors
      if (!mounted) return;
      _isDismissed = false; // Reset flag if error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
      return; // Don't close dialog if error
    }

    // Close the SOS alert dialog
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Parse data
    final emergencyType = widget.data['emergencyType'] ?? 'Khẩn cấp';
    final distance =
        _calculatedDistance ??
        widget.data['distance'] ??
        '---'; // [CHANGED] Use calculated distance
    final reporterName = widget.data['reporterName'] ?? 'Người gặp nạn';
    final manualAddress = widget.data['manualAddress'];

    // [DEBUG] Log to check distance value
    print('═══════════════════════════════════════');
    print('🔍 SOS ALERT DIALOG DATA:');
    print('   Backend distance: ${widget.data['distance']}');
    print('   Calculated distance: $_calculatedDistance');
    print('   Displaying: $distance');
    print('═══════════════════════════════════════');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      elevation: 5,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Icon close
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => _handleDismiss(context),
                child: const Icon(Icons.close, color: Colors.black54),
              ),
            ),

            // Title
            const Text(
              "Yêu Cầu Cứu Hộ\nKhẩn Cấp!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD32F2F), // Màu đỏ cảnh báo
                height: 1.2,
              ),
            ),

            const SizedBox(height: 15),

            // Emergency Type
            Text(
              emergencyType.toString().toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0D47A1), // Xanh dương đậm
              ),
            ),

            const SizedBox(height: 5),

            // Reporter name
            Text(
              reporterName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 5),

            // Subtitle
            const Text(
              "Đang cần sự giúp đỡ của bạn",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // Icon/Avatar SOS
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade100, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(Icons.sos_rounded, size: 60, color: Colors.red),
            ),

            const SizedBox(height: 20),

            // Distance
            Text(
              "Cách bạn ${distance}km",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            // Manual address if available
            if (manualAddress != null &&
                manualAddress.toString().isNotEmpty) ...{
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.place, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        manualAddress.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            },

            const SizedBox(height: 25),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => _handleDismiss(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Bỏ qua",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: widget.onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF4CAF50,
                        ), // Màu xanh chấp nhận
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        "Chấp nhận",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
