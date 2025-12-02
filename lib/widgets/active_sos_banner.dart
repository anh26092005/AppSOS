import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/active_sos_provider.dart';
import '../screens/sos_accepted_screen.dart';

class ActiveSosBanner extends StatefulWidget {
  const ActiveSosBanner({super.key});

  @override
  State<ActiveSosBanner> createState() => _ActiveSosBannerState();
}

class _ActiveSosBannerState extends State<ActiveSosBanner> {
  bool _isExpanded = false;

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

    // Calculate distance if available
    String distance = '---';
    try {
      final reporterLoc = sosCase['location']['coordinates'];
      final volunteerLoc = sosCase['responderLocation']?['coordinates'];

      if (reporterLoc != null && volunteerLoc != null) {
        // For now, just show placeholder - you can calculate actual distance if needed
        distance = '1.2';
      }
    } catch (e) {
      print('Error calculating distance: $e');
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
            colors: [Colors.red.shade400, Colors.red.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.4),
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
                  child: const Icon(Icons.sos, color: Colors.red, size: 24),
                ),

                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.emergency, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'ĐANG ỨNG CỨU',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${reporterInfo['fullName']} • ${_getEmergencyIcon(emergencyType)} $emergencyType • ${distance}km',
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

              // Phone number
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

              const SizedBox(height: 12),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SosAcceptedScreen(sosData: sosData),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
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
