import 'package:flutter/material.dart';

class SOSAlertDialog extends StatelessWidget {
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const SOSAlertDialog({
    super.key,
    required this.title,
    required this.body,
    required this.data,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    // Parse data
    final emergencyType = data['emergencyType'] ?? 'Khẩn cấp';
    final distance = data['distance'] ?? '---';
    // final caseCode = data['caseCode'];

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
                onTap: onDecline,
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
                    color: Colors.red.withOpacity(0.2),
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

            const SizedBox(height: 25),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: onDecline,
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
                      onPressed: onAccept,
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
