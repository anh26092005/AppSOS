import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class SosNotificationDialog extends StatefulWidget {
  final String caseId;
  final String caseCode;
  final String emergencyType;
  final String distance;
  final Function(Map<String, dynamic>)? onAccepted;

  const SosNotificationDialog({
    super.key,
    required this.caseId,
    required this.caseCode,
    required this.emergencyType,
    required this.distance,
    this.onAccepted,
  });

  @override
  State<SosNotificationDialog> createState() => _SosNotificationDialogState();
}

class _SosNotificationDialogState extends State<SosNotificationDialog> {
  bool _isLoading = false;

  Future<void> _handleAccept() async {
    setState(() => _isLoading = true);

    try {
      // Get current location before accepting
      double? latitude;
      double? longitude;

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        latitude = position.latitude;
        longitude = position.longitude;
        print('✅ Got location: $latitude, $longitude');
      } catch (e) {
        print('❌ Error getting location: $e');
        // Continue without location if there's an error
      }

      print('🔄 Calling acceptSosCase API...');
      final response = await ApiService.acceptSosCase(
        widget.caseId,
        latitude: latitude,
        longitude: longitude,
      );

      print('═══════════════════════════════════════');
      print('✅ Accept SOS Response:');
      print('Data: ${response['data']}');
      print('═══════════════════════════════════════');

      if (!mounted) return;

      // Call callback to save to provider
      if (widget.onAccepted != null) {
        widget.onAccepted!(response['data']);
      }

      setState(() => _isLoading = false);

      // Đóng dialog
      Navigator.of(context).pop();

      // Chuyển đến màn hình chi tiết với thông tin người cần cứu
      print('🔄 Navigating to /sos-accepted...');
      Navigator.pushNamed(
        context,
        '/sos-accepted',
        arguments: response['data'],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã chấp nhận yêu cầu SOS'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error in _handleAccept: $e');
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleDecline() async {
    // Hiển thị dialog nhập lý do từ chối
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _DeclineReasonDialog(),
    );

    if (reason == null || reason.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await ApiService.declineSosCase(widget.caseId, reason);

      if (!mounted) return;

      setState(() => _isLoading = false);

      // Đóng dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã từ chối yêu cầu SOS'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _getEmergencyIcon(String type) {
    switch (type) {
      case 'MEDICAL':
        return '🏥';
      case 'FIRE':
        return '🔥';
      case 'ACCIDENT':
        return '🚗';
      case 'CRIME':
        return '🚨';
      case 'NATURAL_DISASTER':
        return '🌪️';
      default:
        return '⚠️';
    }
  }

  String _getEmergencyText(String type) {
    switch (type) {
      case 'MEDICAL':
        return 'Y tế khẩn cấp';
      case 'FIRE':
        return 'Hỏa hoạn';
      case 'ACCIDENT':
        return 'Tai nạn';
      case 'CRIME':
        return 'Tội phạm';
      case 'NATURAL_DISASTER':
        return 'Thiên tai';
      default:
        return 'Khẩn cấp';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.red.shade50, Colors.white],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon khẩn cấp
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.shade100,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _getEmergencyIcon(widget.emergencyType),
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Tiêu đề
            const Text(
              '🚨 TÍN HIỆU KHẨN CẤP',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Thông tin
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.emergency,
                    'Loại khẩn cấp',
                    _getEmergencyText(widget.emergencyType),
                  ),
                  const Divider(height: 20),
                  _buildInfoRow(
                    Icons.location_on,
                    'Khoảng cách',
                    '${widget.distance} km',
                  ),
                  const Divider(height: 20),
                  _buildInfoRow(
                    Icons.confirmation_number,
                    'Mã case',
                    widget.caseCode,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (_isLoading)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  // Nút Chấp nhận
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _handleAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Chấp Nhận Hỗ Trợ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Nút Từ chối
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _handleDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Không thể hỗ trợ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.red.shade400),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Dialog nhập lý do từ chối
class _DeclineReasonDialog extends StatefulWidget {
  @override
  State<_DeclineReasonDialog> createState() => _DeclineReasonDialogState();
}

class _DeclineReasonDialogState extends State<_DeclineReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lý do từ chối'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Nhập lý do...',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            final reason = _controller.text.trim();
            if (reason.isNotEmpty) {
              Navigator.pop(context, reason);
            }
          },
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }
}
