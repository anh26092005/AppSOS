import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class VolunteerRegistrationScreen extends StatefulWidget {
  const VolunteerRegistrationScreen({super.key});

  @override
  State<VolunteerRegistrationScreen> createState() =>
      _VolunteerRegistrationScreenState();
}

class _VolunteerRegistrationScreenState
    extends State<VolunteerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'CN'; // CN: Cá nhân, TC: Tổ chức
  final _orgNameController = TextEditingController();
  final List<String> _selectedSkills = [];
  File? _idCardFront;
  File? _idCardBack;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  final List<String> _availableSkills = [
    'Y tế',
    'Cứu hộ',
    'Sửa xe',
    'Vận chuyển',
    'Nhu yếu phẩm',
    'Tư vấn tâm lý',
    'Khác',
  ];

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isFront) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          if (isFront) {
            _idCardFront = File(image.path);
          } else {
            _idCardBack = File(image.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi chọn ảnh: $e')));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 kỹ năng')),
      );
      return;
    }
    if (_idCardFront == null || _idCardBack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tải lên đủ 2 mặt giấy tờ')),
      );
      return;
    }
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đồng ý với điều khoản')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Lấy vị trí hiện tại
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 2. Upload ảnh
      Map<String, dynamic> frontImage = await ApiService.uploadImage(
        _idCardFront!,
      );
      Map<String, dynamic> backImage = await ApiService.uploadImage(
        _idCardBack!,
      );

      // 3. Lấy userId (đã có trong cached user hoặc backend tự lấy từ token)
      final user = await ApiService.getCachedUser();
      if (user == null) throw Exception('Không tìm thấy thông tin user');

      // 4. Gọi API đăng ký
      final body = {
        'userId': user['_id'],
        'type': _type,
        'skills': _selectedSkills,
        'homeBase': {
          'location': {
            'coordinates': [position.longitude, position.latitude],
          },
          'radiusKm': 5, // Mặc định 5km
        },
        'idCardFront': frontImage,
        'idCardBack': backImage,
      };

      if (_type == 'TC') {
        body['organization'] = _orgNameController.text;
      }

      await ApiService.registerVolunteer(body);

      if (!mounted) return;

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Đăng ký thành công'),
          content: const Text(
            'Hồ sơ của bạn đã được gửi và đang chờ duyệt. Chúng tôi sẽ thông báo cho bạn sớm nhất.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Close dialog
                Navigator.of(context).pop(); // Back to Account screen
              },
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _orgNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký Tình nguyện viên'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin cơ bản',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(
                        labelText: 'Loại hình tham gia',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'CN', child: Text('Cá nhân')),
                        DropdownMenuItem(value: 'TC', child: Text('Tổ chức')),
                      ],
                      onChanged: (val) {
                        setState(() => _type = val!);
                      },
                    ),
                    if (_type == 'TC') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _orgNameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên tổ chức',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (_type == 'TC' && (val == null || val.isEmpty)) {
                            return 'Vui lòng nhập tên tổ chức';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Text(
                      'Kỹ năng hỗ trợ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _availableSkills.map((skill) {
                        final isSelected = _selectedSkills.contains(skill);
                        return FilterChip(
                          label: Text(skill),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedSkills.add(skill);
                              } else {
                                _selectedSkills.remove(skill);
                              }
                            });
                          },
                          selectedColor: Colors.redAccent.withOpacity(0.2),
                          checkmarkColor: Colors.redAccent,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Xác minh danh tính',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Vui lòng tải lên ảnh CCCD/CMND hoặc giấy tờ liên quan',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildImageUpload(
                            'Mặt trước',
                            _idCardFront,
                            () => _pickImage(true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildImageUpload(
                            'Mặt sau',
                            _idCardBack,
                            () => _pickImage(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    CheckboxListTile(
                      value: _agreedToTerms,
                      onChanged: (val) => setState(() => _agreedToTerms = val!),
                      title: const Text(
                        'Tôi cam kết các thông tin trên là chính xác và chịu trách nhiệm về hoạt động tình nguyện của mình.',
                        style: TextStyle(fontSize: 14),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Gửi Đăng Ký',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageUpload(String label, File? image, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              image: image != null
                  ? DecorationImage(image: FileImage(image), fit: BoxFit.cover)
                  : null,
            ),
            child: image == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, color: Colors.grey.shade400),
                      const SizedBox(height: 4),
                      Text(
                        'Tải ảnh lên',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  )
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
