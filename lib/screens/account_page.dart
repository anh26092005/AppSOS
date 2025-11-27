import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Map<String, dynamic>? _user;
  bool _isReady = false;
  bool _isTogglingReady = false;

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

  String _initial() {
    final name = _displayName();
    if (name.isEmpty) return '?';
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 243, 243),
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
                        color: const Color(0xFF0D47A1), // Dark Blue
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Birth Year (Placeholder logic)
                    const Text(
                      "2004", // TODO: Get from user profile
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Bio
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Mờ cương tớiiiiii", // TODO: Get from user profile
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.edit, size: 16, color: Colors.grey.shade600),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Avatar
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
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
                          ),
                          child: CircleAvatar(
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: const AssetImage(
                              'assets/images/default_avatar.png',
                            ), // Fallback
                            // foregroundImage: NetworkImage(_user?['avatar'] ?? ''), // Uncomment when ready
                            child: Text(
                              _initial(),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Edit Avatar Button
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          "Đổi ảnh đại diện",
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
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
                                  color: Colors.white,
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
                                      color: const Color(0xFF333333),
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
                        // TODO: Navigate to settings
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
        color: Colors.white,
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
            color: Colors.redAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFF57F17),
            size: 24,
          ), // Gold/Orange icon
        ),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
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
