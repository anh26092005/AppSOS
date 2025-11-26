import 'package:flutter/material.dart';

class SOSAcceptedDialog extends StatelessWidget {
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final VoidCallback onAction; // Nút hành động chính (Xem vị trí)
  final VoidCallback onClose;

  const SOSAcceptedDialog({
    super.key,
    required this.title,
    required this.body,
    required this.data,
    required this.onAction,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // Parse data
    final volunteerName = data['volunteerName'] ?? 'Tình nguyện viên';
    final volunteerPhone = data['volunteerPhone'] ?? 'Không có SĐT';
    final distance = data['distance'] ?? '---';
    // final avatarUrl = data['volunteerAvatar']; // Nếu có avatar url

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
                onTap: onClose,
                child: const Icon(Icons.reply, color: Colors.black54),
              ),
            ),

            // Title
            const Text(
              "Đã Tìm Thấy\nTình Nguyện Viên",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50), // Màu xanh lá như hình
                height: 1.2,
              ),
            ),

            const SizedBox(height: 15),

            // Name
            Text(
              volunteerName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0D47A1), // Xanh dương đậm
              ),
            ),

            const SizedBox(height: 5),

            // Subtitle (Năm sinh/Bio - Placeholder)
            const Text(
              "Sẵn sàng hỗ trợ bạn",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // Avatar
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                image: const DecorationImage(
                  image: AssetImage(
                    'assets/images/default_avatar.png',
                  ), // Fallback asset
                  fit: BoxFit.cover,
                ),
              ),
              // Nếu có network image thì dùng NetworkImage
              child: const CircleAvatar(
                backgroundColor: Color(0xFFE0E0E0),
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/300',
                ), // Placeholder avatar
              ),
            ),

            const SizedBox(height: 20),

            // Distance
            Text(
              "Cách bạn ${distance}km",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 5),

            // Phone
            Text(
              "SĐT: $volunteerPhone",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 25),

            // Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935), // Màu đỏ như hình
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  "Xem vị trí ngay", // Đổi text cho phù hợp logic
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
