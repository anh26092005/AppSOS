import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../services/permission_service.dart';
import 'dart:io';

class PermissionTestScreen extends StatefulWidget {
  const PermissionTestScreen({super.key});

  @override
  State<PermissionTestScreen> createState() => _PermissionTestScreenState();
}

class _PermissionTestScreenState extends State<PermissionTestScreen> {
  String _locationStatus = 'Chưa xin quyền';
  String _photoStatus = 'Chưa xin quyền';
  String _contactStatus = 'Chưa xin quyền';
  String _cameraStatus = 'Chưa xin quyền';
  File? _selectedImage;
  Position? _currentPosition;
  List<Contact> _contacts = [];

  Future<void> _requestLocationAndGetPosition() async {
    setState(() => _locationStatus = 'Đang xin quyền...');

    bool granted = await PermissionService.requestFineLocationPermission();

    if (granted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _currentPosition = position;
          _locationStatus = 'Đã cấp quyền!\nVị trí: ${position.latitude}, ${position.longitude}';
        });
      } catch (e) {
        setState(() => _locationStatus = 'Lỗi: $e');
      }
    } else {
      setState(() => _locationStatus = 'Bị từ chối');
    }
  }

  Future<void> _requestPhotoAndPick() async {
    setState(() => _photoStatus = 'Đang xin quyền...');

    bool granted = await PermissionService.requestPhotosPermission();

    if (granted) {
      try {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(source: ImageSource.gallery);

        if (image != null) {
          setState(() {
            _selectedImage = File(image.path);
            _photoStatus = 'Đã cấp quyền!\nĐã chọn ảnh';
          });
        } else {
          setState(() => _photoStatus = 'Đã cấp quyền nhưng không chọn ảnh');
        }
      } catch (e) {
        setState(() => _photoStatus = 'Lỗi: $e');
      }
    } else {
      setState(() => _photoStatus = 'Bị từ chối');
    }
  }

  Future<void> _requestCameraAndTakePhoto() async {
    setState(() => _cameraStatus = 'Đang xin quyền...');

    bool granted = await PermissionService.requestCameraPermission();

    if (granted) {
      try {
        final ImagePicker picker = ImagePicker();
        final XFile? photo = await picker.pickImage(source: ImageSource.camera);

        if (photo != null) {
          setState(() {
            _selectedImage = File(photo.path);
            _cameraStatus = 'Đã cấp quyền!\nĐã chụp ảnh';
          });
        } else {
          setState(() => _cameraStatus = 'Đã cấp quyền nhưng không chụp');
        }
      } catch (e) {
        setState(() => _cameraStatus = 'Lỗi: $e');
      }
    } else {
      setState(() => _cameraStatus = 'Bị từ chối');
    }
  }

  Future<void> _requestContactAndRead() async {
    setState(() => _contactStatus = 'Đang xin quyền...');

    bool granted = await PermissionService.requestContactsPermission();

    if (granted) {
      try {
        List<Contact> contacts = await FlutterContacts.getContacts(
          withProperties: true,
        );
        List<Contact> contactList = contacts.take(5).toList();

        setState(() {
          _contacts = contactList;
          _contactStatus = 'Đã cấp quyền!\nĐọc được ${contactList.length} danh bạ';
        });
      } catch (e) {
        setState(() => _contactStatus = 'Lỗi: $e');
      }
    } else {
      setState(() => _contactStatus = 'Bị từ chối');
    }
  }

  Future<void> _requestAllPermissions() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    Map<Permission, PermissionStatus> statuses =
        await PermissionService.requestAllBasicPermissions();

    if (!mounted) return;
    Navigator.pop(context);

    String message = '';
    statuses.forEach((permission, status) {
      message += '${permission.toString()}: ${status.isGranted ? "✓" : "✗"}\n';
    });

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kết quả xin quyền'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Permissions'),
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Demo xin quyền truy cập',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Nhấn vào các nút bên dưới để test xin quyền',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _requestAllPermissions,
              icon: const Icon(Icons.security),
              label: const Text('Xin tất cả quyền cùng lúc'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const Divider(height: 32),

            _buildPermissionCard(
              title: 'Quyền truy cập Vị trí',
              icon: Icons.location_on,
              status: _locationStatus,
              color: Colors.blue,
              onPressed: _requestLocationAndGetPosition,
              child: _currentPosition != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Latitude: ${_currentPosition!.latitude}'),
                        Text('Longitude: ${_currentPosition!.longitude}'),
                      ],
                    )
                  : null,
            ),

            const SizedBox(height: 16),

            _buildPermissionCard(
              title: 'Quyền truy cập Ảnh',
              icon: Icons.photo_library,
              status: _photoStatus,
              color: Colors.green,
              onPressed: _requestPhotoAndPick,
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  : null,
            ),

            const SizedBox(height: 16),

            _buildPermissionCard(
              title: 'Quyền truy cập Camera',
              icon: Icons.camera_alt,
              status: _cameraStatus,
              color: Colors.orange,
              onPressed: _requestCameraAndTakePhoto,
            ),

            const SizedBox(height: 16),

            _buildPermissionCard(
              title: 'Quyền truy cập Danh bạ',
              icon: Icons.contacts,
              status: _contactStatus,
              color: Colors.red,
              onPressed: _requestContactAndRead,
              child: _contacts.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '5 danh bạ đầu tiên:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ..._contacts.map((contact) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('• ${contact.displayName}'),
                            )),
                      ],
                    )
                  : null,
            ),

            const SizedBox(height: 24),

            OutlinedButton.icon(
              onPressed: () => PermissionService.openSettings(),
              icon: const Icon(Icons.settings),
              label: const Text('Mở Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required IconData icon,
    required String status,
    required Color color,
    required VoidCallback onPressed,
    Widget? child,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Trạng thái: $status',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            if (child != null) ...[
              const SizedBox(height: 12),
              child,
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xin quyền'),
            ),
          ],
        ),
      ),
    );
  }
}

