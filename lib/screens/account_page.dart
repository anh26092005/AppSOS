import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../widgets/user_avatar.dart';
import '../widgets/avatar_upload_dialog.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Map<String, dynamic>? _user;
  bool _isReady = false;
  bool _isTogglingReady = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final cached = await ApiService.getCachedUser();
    if (mounted && cached != null) {
      setState(() {
        _user = cached;
        final volunteerProfile = cached['volunteerProfile'];
        if (volunteerProfile != null && volunteerProfile is Map) {
          _isReady = volunteerProfile['ready'] ?? false;
        }
      });
    }
    await _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    try {
      final user = await ApiService.fetchProfile();
      if (!mounted) return;
      setState(() {
        _user = user;
        final volunteerProfile = user['volunteerProfile'];
        if (volunteerProfile != null && volunteerProfile is Map) {
          _isReady = volunteerProfile['ready'] ?? false;
        }
      });
    } catch (e) {
      print('Error loading profile: $e');
    }
  }

  String _stringValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  String _displayName() {
    final fullName = _stringValue(_user?['fullName']).trim();
    if (fullName.isNotEmpty) return fullName;
    final name = _stringValue(_user?['name']).trim();
    if (name.isNotEmpty) return name;
    final email = _stringValue(_user?['email']).trim();
    if (email.isNotEmpty) return email;
    final phone = _stringValue(_user?['phone']).trim();
    if (phone.isNotEmpty) return phone;
    return 'User';
  }

  String? _getAvatarUrl(dynamic avatar) {
    if (avatar == null) return null;
    if (avatar is String) return avatar;
    if (avatar is Map<String, dynamic>) {
      return avatar['url'] as String?;
    }
    return null;
  }

  Future<void> _handleAvatarUpload() async {
    try {
      final XFile? imageFile = await AvatarUploadDialog.show(context);
      if (imageFile == null) return;

      setState(() => _isUploadingAvatar = true);

      await ApiService.updateAvatar(File(imageFile.path));
      await _refreshProfile();

      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật ảnh đại diện'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getBio() {
    final bio = _stringValue(_user?['bio']).trim();
    if (bio.isNotEmpty) return bio;
    return 'Chưa có giới thiệu bản thân';
  }

  String _getBirthYear() {
    final dateOfBirth = _user?['dateOfBirth'];
    if (dateOfBirth == null) return ' ';
    try {
      final date = DateTime.parse(dateOfBirth);
      return date.year.toString();
    } catch (e) {
      return 'Cập nhật năm sinh';
    }
  }

  Future<void> _showEditBioDialog() async {
    final TextEditingController bioController = TextEditingController(
      text: _stringValue(_user?['bio']).trim(),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa giới thiệu'),
        backgroundColor: Theme.of(context).cardColor,
        content: TextField(
          controller: bioController,
          maxLines: 3,
          maxLength: 25,
          decoration: InputDecoration(
            hintText: 'Nhập giới thiệu về bạn...',
            border: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.cyan, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.cyan, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.blue, width: 2.5),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result == true) {
      final newBio = bioController.text.trim();
      try {
        await ApiService.updateProfile(bio: newBio);
        await _refreshProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật giới thiệu'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // HEADER SECTION (New Design)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 60, // Space for status bar
                  bottom: 30,
                  left: 20,
                  right: 20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: Theme.of(context).brightness == Brightness.dark
                        ? [
                            Theme.of(context).colorScheme.surface,
                            Theme.of(context).colorScheme.surfaceVariant,
                          ]
                        : [
                            const Color(0xFFFFF8E1), // Light beige
                            const Color(0xFFFFECB3), // Slightly deeper beige
                          ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Name
                    Text(
                      _displayName(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF0D47A1), // Dark Blue
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Birth Year
                    Text(
                      _getBirthYear(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Bio
                    GestureDetector(
                      onTap: _showEditBioDialog,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _getBio(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Avatar - Using UserAvatar widget
                    _isUploadingAvatar
                        ? Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: Colors.grey.shade200,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFF6C343),
                              ),
                            ),
                          )
                        : UserAvatar(
                            avatarUrl: _getAvatarUrl(_user?['avatar']),
                            name: _displayName(),
                            size: AvatarSize.large,
                          ),
                    const SizedBox(height: 12),
                    // Edit Avatar Button
                    GestureDetector(
                      onTap: _isUploadingAvatar ? null : _handleAvatarUpload,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit,
                            size: 14,
                            color: _isUploadingAvatar
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isUploadingAvatar
                                ? "Đang tải lên..."
                                : "Đổi ảnh đại diện",
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _isUploadingAvatar
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // BODY SECTION (Original Design restored)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildAccountTile(
                      context,
                      icon: Icons.person_outline,
                      title: 'Hồ sơ',
                      subtitle: 'Xem và chỉnh sửa thông tin',
                      onTap: () {
                        Navigator.pushNamed(context, '/account');
                      },
                    ),
                    const SizedBox(height: 12),

                    // Volunteer Menu Item
                    Builder(
                      builder: (context) {
                        final roles = _user?['roles'];
                        bool isTNV = false;
                        if (roles is List) {
                          isTNV =
                              roles.contains('TNV_CN') ||
                              roles.contains('TNV_TC');
                        } else if (roles is String) {
                          isTNV = roles == 'TNV_CN' || roles == 'TNV_TC';
                        }
                        final volunteerStatus =
                            _user?['volunteerStatus']; // PENDING, APPROVED, REJECTED

                        // 1. Đã là TNV (APPROVED)
                        if (isTNV) {
                          return Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:
                                          (_isReady
                                                  ? Colors.green
                                                  : Colors.grey)
                                              .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _isReady
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: _isReady
                                          ? Colors.green
                                          : Colors.grey,
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    'Trạng thái hoạt động',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      _isReady
                                          ? 'Đang sẵn sàng nhận yêu cầu'
                                          : 'Tắt nhận yêu cầu SOS',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: _isReady
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  trailing: _isTogglingReady
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Switch(
                                          value: _isReady,
                                          onChanged: (value) async {
                                            setState(() {
                                              _isTogglingReady = true;
                                            });
                                            try {
                                              final response =
                                                  await ApiService.toggleVolunteerReady();
                                              final data = response['data'];
                                              final newReadyStatus =
                                                  data['ready'] ?? false;
                                              setState(() {
                                                _isReady = newReadyStatus;
                                                _isTogglingReady = false;
                                              });
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    newReadyStatus
                                                        ? 'Đã bật nhận yêu cầu SOS'
                                                        : 'Đã tắt nhận yêu cầu SOS',
                                                  ),
                                                  backgroundColor:
                                                      newReadyStatus
                                                      ? Colors.green
                                                      : Colors.grey,
                                                ),
                                              );
                                            } catch (e) {
                                              setState(() {
                                                _isTogglingReady = false;
                                              });
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text('Lỗi: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                          activeColor: Colors.green,
                                        ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildAccountTile(
                                context,
                                icon: Icons.badge_outlined,
                                title: 'Xem hồ sơ tình nguyện viên',
                                subtitle: 'Quản lý hồ sơ TNV của bạn',
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/info-tnv',
                                    arguments: _user,
                                  );
                                },
                              ),
                            ],
                          );
                        }

                        // 2. Đang chờ duyệt (PENDING)
                        if (volunteerStatus == 'PENDING') {
                          return _buildAccountTile(
                            context,
                            icon: Icons.hourglass_empty,
                            title: 'Hồ sơ đang chờ duyệt',
                            subtitle: 'Vui lòng chờ quản trị viên xác nhận',
                            // iconColor: Colors.orange, // Helper chưa hỗ trợ iconColor, cần sửa helper hoặc bỏ qua
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Đang xét duyệt'),
                                  content: const Text(
                                    'Hồ sơ đăng ký tình nguyện viên của bạn đang được ban quản trị xem xét. Chúng tôi sẽ thông báo khi có kết quả.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Đóng'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }

                        // 3. Bị từ chối (REJECTED)
                        if (volunteerStatus == 'REJECTED') {
                          return _buildAccountTile(
                            context,
                            icon: Icons.error_outline,
                            title: 'Đăng ký bị từ chối',
                            subtitle: 'Nhấn để đăng ký lại',
                            // iconColor: Colors.red,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/volunteer-registration',
                              );
                            },
                          );
                        }

                        // 4. Chưa đăng ký (hoặc user thường)
                        return _buildAccountTile(
                          context,
                          icon: Icons.volunteer_activism,
                          title: 'Đăng ký làm tình nguyện viên',
                          subtitle: 'Tham gia cứu hộ cộng đồng',
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/volunteer-registration',
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 12),
                    _buildAccountTile(
                      context,
                      icon: Icons.settings_outlined,
                      title: 'Cài đặt',
                      subtitle: 'Tùy chỉnh ứng dụng',
                      onTap: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildAccountTile(
                      context,
                      icon: Icons.help_outline,
                      title: 'Trợ giúp & Hỗ trợ',
                      subtitle: 'Câu hỏi thường gặp',
                      onTap: () {
                        // TODO: Navigate to help
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildAccountTile(
                      context,
                      icon: Icons.info_outline,
                      title: 'Về ứng dụng',
                      subtitle: 'Thông tin phiên bản',
                      onTap: () {
                        // TODO: Navigate to about
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.redAccent.withValues(alpha: 0.2)
                : Colors.redAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.redAccent
                : const Color(0xFFF57F17),
            size: 24,
          ), // Gold/Orange icon
        ),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 18,
          color: Colors.grey.shade400,
        ),
        onTap: onTap,
      ),
    );
  }
}
