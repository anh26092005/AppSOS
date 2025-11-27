import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  String? _error;

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
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = await ApiService.fetchProfile();
      if (!mounted) return;
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _stringValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  // Get Firebase Auth user if logged in via Google/Facebook
  User? _getFirebaseUser() {
    return AuthService.currentUser;
  }

  String _displayName() {
    // Priority 1: Firebase Auth displayName (from Google/Facebook)
    final firebaseUser = _getFirebaseUser();
    if (firebaseUser != null && firebaseUser.displayName != null && firebaseUser.displayName!.isNotEmpty) {
      return firebaseUser.displayName!;
    }

    // Priority 2: Backend API data
    final fullName = _stringValue(_user?['fullName']).trim();
    if (fullName.isNotEmpty) return fullName;

    final name = _stringValue(_user?['name']).trim();
    if (name.isNotEmpty) return name;

    // Priority 3: Firebase email
    if (firebaseUser != null && firebaseUser.email != null && firebaseUser.email!.isNotEmpty) {
      return firebaseUser.email!;
    }

    final email = _stringValue(_user?['email']).trim();
    if (email.isNotEmpty) return email;

    final phone = _stringValue(_user?['phone']).trim();
    if (phone.isNotEmpty) return phone;

    return 'User';
  }

  String _displayEmail() {
    // Priority 1: Firebase Auth email
    final firebaseUser = _getFirebaseUser();
    if (firebaseUser != null && firebaseUser.email != null && firebaseUser.email!.isNotEmpty) {
      return firebaseUser.email!;
    }

    // Priority 2: Backend API email
    final email = _stringValue(_user?['email']).trim();
    if (email.isNotEmpty) return email;

    return '';
  }

  String? _getPhotoUrl() {
    // Get photo from Firebase Auth (Google/Facebook profile pic)
    final firebaseUser = _getFirebaseUser();
    if (firebaseUser != null && firebaseUser.photoURL != null && firebaseUser.photoURL!.isNotEmpty) {
      return firebaseUser.photoURL;
    }
    return null;
  }

  String _displayInitial() {
    final name = _displayName();
    if (name.isEmpty) return '?';
    return name.substring(0, 1).toUpperCase();
  }

  Widget _buildLoading() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 200),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
        const SizedBox(height: 16),
        const Text(
          'Không thể tải thông tin hồ sơ',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _error ?? 'Lỗi không xác định',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _refreshProfile,
          child: const Text('Thử lại'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hồ sơ')),
        body: _buildLoading(),
      );
    }

    if (_error != null && _user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hồ sơ')),
        body: RefreshIndicator(
          onRefresh: _refreshProfile,
          child: _buildError(),
        ),
      );
    }

    final name = _displayName();
    final email = _displayEmail();
    final phone = _stringValue(_user?['phone']);
    final role = _stringValue(_user?['role']);
    final userId = _stringValue(_user?['id']);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 60,
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
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Back Button (Custom)
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
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _getPhotoUrl() != null 
                              ? NetworkImage(_getPhotoUrl()!) 
                              : null,
                          child: _getPhotoUrl() == null
                              ? Text(
                                  _displayInitial(),
                                  style: GoogleFonts.montserrat(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade500,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF57F17), // Orange/Gold
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email.isNotEmpty ? email : 'Email chưa cập nhật',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Body Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Thông tin cá nhân'),
                  const SizedBox(height: 12),
                  _buildInfoTile(
                    icon: Icons.person_outline,
                    title: 'Họ và tên',
                    value: name,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _buildInfoTile(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    value: email.isNotEmpty ? email : 'Chưa cập nhật',
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _buildInfoTile(
                    icon: Icons.phone_outlined,
                    title: 'Số điện thoại',
                    value: phone.isNotEmpty ? phone : 'Chưa cập nhật',
                    onTap: () {},
                  ),
                  if (role.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildInfoTile(
                      icon: Icons.verified_user_outlined,
                      title: 'Vai trò',
                      value: role,
                      showEdit: false,
                    ),
                  ],
                  if (userId.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildInfoTile(
                      icon: Icons.fingerprint,
                      title: 'User ID',
                      value: userId,
                      showEdit: false,
                    ),
                  ],

                  const SizedBox(height: 24),
                  _buildSectionTitle('Bảo mật'),
                  const SizedBox(height: 12),
                  _buildInfoTile(
                    icon: Icons.lock_outline,
                    title: 'Đổi mật khẩu',
                    value: '••••••••',
                    isAction: true,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  Container(
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
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.security,
                          color: Color(0xFFF57F17),
                          size: 24,
                        ),
                      ),
                      title: Text(
                        'Xác thực 2 lớp (2FA)',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      trailing: Switch(
                        value: false,
                        activeColor: const Color(0xFFF57F17),
                        onChanged: (value) {},
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
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
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        'Xóa tài khoản',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      onTap: () {
                        // TODO: Implement delete account
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ApiService.clearSession();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: Text(
                        'Đăng xuất',
                        style: GoogleFonts.montserrat(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Lỗi: $_error',
                      style: GoogleFonts.montserrat(color: Colors.redAccent),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
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

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
    bool showEdit = true,
    bool isAction = false,
  }) {
    return Container(
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFF57F17), size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        subtitle: Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        trailing: showEdit
            ? Icon(
                isAction ? Icons.arrow_forward_ios_rounded : Icons.edit,
                size: 18,
                color: Colors.grey.shade400,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
