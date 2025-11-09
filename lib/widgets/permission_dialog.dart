import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionDialog {
  static const String _keyPermissionAsked = 'permission_already_asked';

  /// Kiểm tra xem đã xin quyền chưa
  static Future<bool> hasAskedPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPermissionAsked) ?? false;
  }

  /// Đánh dấu đã xin quyền
  static Future<void> markPermissionsAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPermissionAsked, true);
  }

  /// Hiển thị dialog xin quyền đẹp mắt
  static Future<void> show(BuildContext context) async {
    // Kiểm tra xem đã xin quyền chưa
    final hasAsked = await hasAskedPermissions();
    if (hasAsked) {
      return; // Đã xin rồi, không hiện nữa
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PermissionDialogContent(),
    );
  }
}

class _PermissionDialogContent extends StatefulWidget {
  @override
  State<_PermissionDialogContent> createState() =>
      _PermissionDialogContentState();
}

class _PermissionDialogContentState extends State<_PermissionDialogContent> {
  bool _isRequesting = false;

  final List<Map<String, dynamic>> _permissions = [
    {
      'icon': Icons.location_on,
      'color': Colors.blue,
      'title': 'Vị trí',
      'description': 'Để chia sẻ vị trí của bạn khi khẩn cấp',
      'status': 'pending',
    },
    {
      'icon': Icons.camera_alt,
      'color': Colors.orange,
      'title': 'Camera',
      'description': 'Để chụp ảnh bằng chứng khi cần',
      'status': 'pending',
    },
    {
      'icon': Icons.photo_library,
      'color': Colors.green,
      'title': 'Thư viện ảnh',
      'description': 'Để chọn ảnh từ thư viện của bạn',
      'status': 'pending',
    },
    {
      'icon': Icons.contacts,
      'color': Colors.red,
      'title': 'Danh bạ',
      'description': 'Để thêm danh bạ khẩn cấp',
      'status': 'pending',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon và tiêu đề
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.red.shade700],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(Icons.security, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'Cấp quyền truy cập',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ứng dụng cần một số quyền để hoạt động tốt nhất',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            // Danh sách quyền
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _permissions.length,
                itemBuilder: (context, index) {
                  final perm = _permissions[index];
                  return _buildPermissionItem(
                    icon: perm['icon'],
                    color: perm['color'],
                    title: perm['title'],
                    description: perm['description'],
                    status: perm['status'],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Nút hành động
            if (_isRequesting)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _requestAllPermissions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cấp quyền',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _skipPermissions,
                    child: const Text(
                      'Bỏ qua',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required String status,
  }) {
    IconData statusIcon;
    Color statusColor;

    switch (status) {
      case 'granted':
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case 'denied':
        statusIcon = Icons.cancel;
        statusColor = Colors.red;
        break;
      default:
        statusIcon = Icons.radio_button_unchecked;
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == 'granted'
              ? Colors.green.shade200
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Icon(statusIcon, color: statusColor, size: 24),
        ],
      ),
    );
  }

  Future<void> _requestAllPermissions() async {
    setState(() {
      _isRequesting = true;
    });

    // Xin quyền vị trí
    bool locationGranted =
        await PermissionService.requestFineLocationPermission();
    setState(() {
      _permissions[0]['status'] = locationGranted ? 'granted' : 'denied';
    });

    await Future.delayed(const Duration(milliseconds: 300));

    // Xin quyền camera
    bool cameraGranted = await PermissionService.requestCameraPermission();
    setState(() {
      _permissions[1]['status'] = cameraGranted ? 'granted' : 'denied';
    });

    await Future.delayed(const Duration(milliseconds: 300));

    // Xin quyền ảnh
    bool photosGranted = await PermissionService.requestPhotosPermission();
    setState(() {
      _permissions[2]['status'] = photosGranted ? 'granted' : 'denied';
    });

    await Future.delayed(const Duration(milliseconds: 300));

    // Xin quyền danh bạ
    bool contactsGranted = await PermissionService.requestContactsPermission();
    setState(() {
      _permissions[3]['status'] = contactsGranted ? 'granted' : 'denied';
    });

    setState(() {
      _isRequesting = false;
    });

    // Đánh dấu đã xin quyền
    await PermissionDialog.markPermissionsAsked();

    // Đợi 1 giây để người dùng xem kết quả
    await Future.delayed(const Duration(seconds: 1));

    // Lấy vị trí ngay nếu được cấp quyền
    if (locationGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        print('✅ Vị trí đã lấy: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        print('⚠️ Lỗi lấy vị trí: $e');
      }
    }

    if (!mounted) return;

    // Hiển thị thông báo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          locationGranted
              ? '✅ Đã cấp quyền vị trí thành công!'
              : '⚠️ Một số quyền bị từ chối',
        ),
        backgroundColor: locationGranted ? Colors.green : Colors.orange,
      ),
    );

    // Đóng dialog
    Navigator.pop(context);
  }

  Future<void> _skipPermissions() async {
    // Đánh dấu đã xin quyền (để không hiện lại)
    await PermissionDialog.markPermissionsAsked();

    if (!mounted) return;
    Navigator.pop(context);
  }
}
