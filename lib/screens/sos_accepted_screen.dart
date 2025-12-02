import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../providers/active_sos_provider.dart';

class SosAcceptedScreen extends StatefulWidget {
  final Map<String, dynamic> sosData;

  const SosAcceptedScreen({super.key, required this.sosData});

  @override
  State<SosAcceptedScreen> createState() => _SosAcceptedScreenState();
}

class _SosAcceptedScreenState extends State<SosAcceptedScreen> {
  late final Map<String, dynamic> _case;
  late final Map<String, dynamic> _reporterInfo;
  late final LatLng _reporterPosition;
  late final LatLng _volunteerPosition;
  Timer? _distanceTimer;
  double? _distanceInKm;
  String? _estimatedTime;

  @override
  void initState() {
    super.initState();

    print('═══════════════════════════════════════');
    print('📱 SosAcceptedScreen initState');
    print('sosData keys: ${widget.sosData.keys}');
    print('sosData: ${widget.sosData}');
    print('═══════════════════════════════════════');

    _case = widget.sosData['case'];
    print('Case: $_case');

    _reporterInfo = _case['reporterId'];
    print('Reporter info: $_reporterInfo');

    // Lấy tọa độ reporter
    final reporterLoc = _case['location']['coordinates'];
    _reporterPosition = LatLng(reporterLoc[1], reporterLoc[0]);
    print('Reporter position: $_reporterPosition');

    // Lấy tọa độ volunteer
    final volunteerLoc = _case['responderLocation']['coordinates'];
    _volunteerPosition = LatLng(volunteerLoc[1], volunteerLoc[0]);
    print('Volunteer position: $_volunteerPosition');
    print('═══════════════════════════════════════');

    // Calculate distance initially and every 10 seconds
    _calculateDistance();
    _distanceTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _calculateDistance();
    });
  }

  @override
  void dispose() {
    _distanceTimer?.cancel();
    super.dispose();
  }

  Future<void> _calculateDistance() async {
    try {
      // Get volunteer's current position
      Position volunteerCurrentPosition = await Geolocator.getCurrentPosition();

      // Calculate distance between volunteer and reporter
      double distanceInMeters = Geolocator.distanceBetween(
        volunteerCurrentPosition.latitude,
        volunteerCurrentPosition.longitude,
        _reporterPosition.latitude,
        _reporterPosition.longitude,
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
              : 'Đã đến';
        });
      }
    } catch (e) {
      print('Error calculating distance: $e');
    }
  }

  Future<void> _openDirections() async {
    final directionsUrl = widget.sosData['directionsUrl'];
    if (directionsUrl != null) {
      final uri = Uri.parse(directionsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở Google Maps')),
        );
      }
    }
  }

  Future<void> _makePhoneCall() async {
    final phone = _reporterInfo['phone'];
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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

  Future<void> _completeRescue() async {
    final shouldComplete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác nhận hoàn thành',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bạn có chắc chắn đã hoàn thành ứng cứu? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Chưa'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );

    if (shouldComplete != true) return;

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final caseId = _case['_id'];
      await ApiService.completeSosCase(caseId);

      if (!mounted) return;

      // Clear from provider
      await context.read<ActiveSosProvider>().clearActiveCase();

      Navigator.pop(context); // Close loading

      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              const SizedBox(width: 12),
              const Text(
                'Thành công',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text('Đã hoàn thành ứng cứu thành công!'),
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
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi hoàn thành: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Thông tin người cần cứu'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map
            Container(
              height: 300,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _reporterPosition,
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app_sos',
                  ),
                  MarkerLayer(
                    markers: [
                      // Reporter marker (red)
                      Marker(
                        point: _reporterPosition,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.person_pin_circle,
                          size: 40,
                          color: Colors.red,
                        ),
                      ),
                      // Volunteer marker (green)
                      Marker(
                        point: _volunteerPosition,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.navigation,
                          size: 40,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Thông tin khẩn cấp
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emergency Type Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getEmergencyIcon(_case['emergencyType']),
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _case['emergencyType'],
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_case['isUrgent'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'KHẨN CẤP',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Thông tin người cần cứu
                  const Text(
                    'Thông tin người cần cứu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildInfoCard(
                    icon: Icons.person,
                    label: 'Họ tên',
                    value: _reporterInfo['fullName'] ?? 'N/A',
                  ),

                  _buildInfoCard(
                    icon: Icons.phone,
                    label: 'Số điện thoại',
                    value: _reporterInfo['phone'] ?? 'N/A',
                    onTap: _makePhoneCall,
                    actionIcon: Icons.call,
                  ),

                  _buildInfoCard(
                    icon: Icons.description,
                    label: 'Mô tả tình huống',
                    value: _case['description'] ?? 'N/A',
                  ),

                  if (_case['manualAddress'] != null)
                    _buildInfoCard(
                      icon: Icons.location_on,
                      label: 'Địa chỉ',
                      value: _case['manualAddress'],
                    ),

                  if (_case['batteryLevel'] != null)
                    _buildInfoCard(
                      icon: Icons.battery_std,
                      label: 'Pin thiết bị',
                      value: '${_case['batteryLevel']}%',
                    ),

                  // Distance and ETA card
                  if (_distanceInKm != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.blue.shade50, Colors.blue.shade100],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.blue.shade300,
                          width: 2,
                        ),
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
                              Icons.navigation,
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
                                  'Khoảng cách: ${_distanceInKm!.toStringAsFixed(1)} km',
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
                  ],

                  const SizedBox(height: 24),

                  // Nút chỉ đường
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _openDirections,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.navigation, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Mở Google Maps chỉ đường',
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

                  // Nút hoàn thành ứng cứu
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _completeRescue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Hoàn thành ứng cứu',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    IconData? actionIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.red, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                if (actionIcon != null)
                  Icon(actionIcon, color: Colors.blue, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
