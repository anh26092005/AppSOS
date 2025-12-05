import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/active_sos_provider.dart';
import '../screens/sos_accepted_screen.dart';
import '../screens/sos_found_screen.dart';
import '../services/api_service.dart';
import 'package:geolocator/geolocator.dart';

class ActiveSosBanner extends StatefulWidget {
  const ActiveSosBanner({super.key});

  @override
  State<ActiveSosBanner> createState() => _ActiveSosBannerState();
}

class _ActiveSosBannerState extends State<ActiveSosBanner> {
  bool _isExpanded = false;
  String? _currentUserId;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _loadCurrentUser() async {
    final user = await ApiService.getCachedUser();
    if (mounted && user != null) {
      setState(() {
        _currentUserId = user['id'] ?? user['_id'];
      });
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActiveSosProvider>();

    if (!provider.hasActiveCase) {
      return const SizedBox.shrink();
    }

    final sosData = provider.activeSosCase!;
    final sosCase = sosData['case'];
    final reporterInfo = sosCase['reporterId'];
    final emergencyType = sosCase['emergencyType'];
    final status = sosCase['status'];

    // Determine role
    final isReporter =
        _currentUserId != null &&
        (reporterInfo['_id'] == _currentUserId ||
            reporterInfo['id'] == _currentUserId);

    // Volunteer info (if accepted)
    final acceptedBy = sosCase['acceptedBy'];
    final volunteerName = acceptedBy != null ? acceptedBy['fullName'] : 'TNV';

    // Display Logic
    String title = 'ĐANG ỨNG CỨU';
    String subtitle = '';
    String distanceDisplay = '';
    Color bannerColor = Colors.red;
    IconData statusIcon = Icons.emergency;

    if (isReporter) {
      if (status == 'SEARCHING') {
        title = 'ĐANG TÌM KIẾM';
        subtitle = 'Đang tìm tình nguyện viên gần bạn...';
        bannerColor = Colors.orange;
        statusIcon = Icons.search;
      } else if (status == 'ACCEPTED' || status == 'IN_PROGRESS') {
        title = 'ĐÃ TÌM THẤY';
        subtitle = '$volunteerName đang đến hỗ trợ bạn!';
        bannerColor = Colors.green;
        statusIcon = Icons.check_circle;
      }
    } else {
      // Volunteer View
      title = 'ĐANG ỨNG CỨU';
      subtitle =
          '${reporterInfo['fullName']} • ${_getEmergencyIcon(emergencyType)} $emergencyType';

      // Calculate distance if available
      try {
        final reporterLoc = sosCase['location']['coordinates'];
        // Note: sosCase['responderLocation'] is not used for distance calc here,
        // we use current user's location vs reporter location

        if (reporterLoc != null && _currentPosition != null) {
          final double distMeters = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            reporterLoc[1], // lat
            reporterLoc[0], // lng
          );

          if (distMeters < 1000) {
            distanceDisplay = ' • ${distMeters.toStringAsFixed(0)}m';
          } else {
            distanceDisplay = ' • ${(distMeters / 1000).toStringAsFixed(1)}km';
          }
        }
      } catch (e) {
        print('Error calculating distance: $e');
      }
      subtitle += distanceDisplay;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bannerColor.withOpacity(0.8), bannerColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: bannerColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Collapsed view (always visible)
            Row(
              children: [
                // SOS Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.sos, color: bannerColor, size: 24),
                ),

                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(statusIcon, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Expand/Collapse icon
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white,
                ),
              ],
            ),

            // Expanded view (conditional)
            if (_isExpanded) ...[
              const Divider(color: Colors.white54, height: 24),

              // Additional Info
              if (isReporter) ...[
                // Reporter specific info
                if (status == 'ACCEPTED' || status == 'IN_PROGRESS')
                  Row(
                    children: [
                      const Icon(Icons.phone, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        acceptedBy != null
                            ? acceptedBy['phone'] ?? 'N/A'
                            : 'N/A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
              ] else ...[
                // Volunteer specific info
                Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      reporterInfo['phone'] ?? 'N/A',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isReporter) {
                      // Navigate to SOS Found Screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SosFoundScreen(
                            caseId: sosCase['_id'],
                            caseData: sosCase,
                          ),
                        ),
                      );
                    } else {
                      // Navigate to SOS Accepted Screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SosAcceptedScreen(sosData: sosData),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: bannerColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Xem chi tiết',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
