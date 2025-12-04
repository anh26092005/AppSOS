import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../utils/app_strings.dart';

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
    'medical',
    'rescue',
    'vehicleRepair',
    'transport',
    'essentials',
    'counseling',
    'other',
  ];
  
  String _getSkillName(String key) => AppStrings.get(key);

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
      ).showSnackBar(SnackBar(content: Text('${AppStrings.get('errorPickingImage')}: $e')));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get('selectAtLeastOneSkill'))),
      );
      return;
    }
    if (_idCardFront == null || _idCardBack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get('uploadBothSides'))),
      );
      return;
    }
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get('agreeToTerms'))),
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
      if (user == null) throw Exception(AppStrings.get('userNotFound'));

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
          title: Text(AppStrings.get('registrationSuccess')),
          content: Text(
            AppStrings.get('registrationPending'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Close dialog
                Navigator.of(context).pop(); // Back to Account screen
              },
              child: Text(AppStrings.get('close')),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${AppStrings.get('error')}: $e')));
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
      backgroundColor: Colors.white,
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF8E1), // Light beige (matching home header)
              Colors.white,
              Colors.white,
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Custom Header with Back Button
                        SizedBox(
                          width: double.infinity,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(left: 0),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                              ),
                              Text(
                              AppStrings.get('volunteerRegistration'),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppStrings.get('basicInfo'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _type,
                          decoration: InputDecoration(
                            labelText: AppStrings.get('participationType'),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'CN',
                            child: Text(AppStrings.get('individual')),
                            ),
                            DropdownMenuItem(
                              value: 'TC',
                            child: Text(AppStrings.get('organization')),
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
                            decoration: InputDecoration(
                              labelText: AppStrings.get('organizationName'),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) {
                              if (_type == 'TC' &&
                                  (val == null || val.isEmpty)) {
                                return AppStrings.get('pleaseEnterOrgName');
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                        Text(
                          AppStrings.get('supportSkills'),
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
                              label: Text(_getSkillName(skill)),
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
                        Text(
                          AppStrings.get('identityVerification'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.get('uploadIdInstruction'),
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildImageUpload(
                                AppStrings.get('frontSide'),
                                _idCardFront,
                                () => _pickImage(true),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildImageUpload(
                                AppStrings.get('backSide'),
                                _idCardBack,
                                () => _pickImage(false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        CheckboxListTile(
                          value: _agreedToTerms,
                          onChanged: (val) =>
                              setState(() => _agreedToTerms = val!),
                          title: Text(
                            AppStrings.get('commitment'),
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
                            child: Text(
                              AppStrings.get('submitRegistration'),
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
        ),
      ),
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
                        AppStrings.get('uploadPhoto'),
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
