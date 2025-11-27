import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                      top: 60,
                      bottom: 24,
                      left: 20,
                      right: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFFF8E1), // Light beige
                          Color(0xFFFFECB3), // Slightly deeper beige
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Đăng ký Tình nguyện viên',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tham gia mạng lưới cứu hộ cộng đồng',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Thông tin cơ bản'),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  value: _type,
                                  decoration: _inputDecoration(
                                    'Loại hình tham gia',
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'CN',
                                      child: Text(
                                        'Cá nhân',
                                        style: GoogleFonts.montserrat(),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'TC',
                                      child: Text(
                                        'Tổ chức',
                                        style: GoogleFonts.montserrat(),
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    setState(() => _type = val!);
                                  },
                                ),
                                if (_type == 'TC') ...[
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _orgNameController,
                                    decoration: _inputDecoration('Tên tổ chức'),
                                    style: GoogleFonts.montserrat(),
                                    validator: (val) {
                                      if (_type == 'TC' &&
                                          (val == null || val.isEmpty)) {
                                        return 'Vui lòng nhập tên tổ chức';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                          _buildSectionTitle('Kỹ năng hỗ trợ'),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _availableSkills.map((skill) {
                                final isSelected = _selectedSkills.contains(
                                  skill,
                                );
                                return FilterChip(
                                  label: Text(
                                    skill,
                                    style: GoogleFonts.montserrat(
                                      color: isSelected
                                          ? const Color(0xFFD84315)
                                          : Colors.black87,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
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
                                  backgroundColor: Colors.grey.shade100,
                                  selectedColor: const Color(0xFFFFF8E1),
                                  checkmarkColor: const Color(0xFFF57F17),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: isSelected
                                          ? const Color(0xFFF57F17)
                                          : Colors.transparent,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 24),
                          _buildSectionTitle('Xác minh danh tính'),
                          const SizedBox(height: 4),
                          Text(
                            'Vui lòng tải lên ảnh CCCD/CMND hoặc giấy tờ liên quan',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
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
                          ),

                          const SizedBox(height: 24),
                          CheckboxListTile(
                            value: _agreedToTerms,
                            onChanged: (val) =>
                                setState(() => _agreedToTerms = val!),
                            title: Text(
                              'Tôi cam kết các thông tin trên là chính xác và chịu trách nhiệm về hoạt động tình nguyện của mình.',
                              style: GoogleFonts.montserrat(fontSize: 13),
                            ),
                            activeColor: const Color(0xFFF57F17),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),

                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF6F00),
                                      Color(0xFFD84315),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFD84315,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Text(
                                    'GỬI ĐĂNG KÝ',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF333333),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.montserrat(color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF57F17), width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildImageUpload(String label, File? image, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1),
              image: image != null
                  ? DecorationImage(image: FileImage(image), fit: BoxFit.cover)
                  : null,
            ),
            child: image == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Color(0xFFF57F17),
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tải ảnh lên',
                        style: GoogleFonts.montserrat(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
