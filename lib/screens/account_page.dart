import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Map<String, dynamic>? _user;

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
      backgroundColor: Colors.white,
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
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF8E1), // Beige background
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    // Name
                    Text(
                      _displayName(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0D47A1), // Dark Blue
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
                          style: TextStyle(
                            fontSize: 14,
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
                        final role = _user?['role'] ?? 'user';
                        final isTNV = role == 'tnv_cn' || role == 'tnv_tc';
                        final volunteerStatus =
                            _user?['volunteerStatus']; // PENDING, APPROVED, REJECTED

                        // 1. Đã là TNV (APPROVED)
                        if (isTNV) {
                          return _buildAccountTile(
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
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await ApiService.clearSession();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/welcome');
                          }
                        },
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text(
                          'Đăng xuất',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
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
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.redAccent),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
