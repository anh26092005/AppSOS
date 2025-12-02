import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/api_service.dart';
import '../widgets/user_avatar.dart';
import '../widgets/avatar_upload_dialog.dart';
import 'create_article_screen.dart';
import '../utils/app_strings.dart';
import '../providers/locale_provider.dart';
import 'package:provider/provider.dart';

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
        _showCustomSnackBar(context, AppStrings.get('avatarUpdated'));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        _showCustomSnackBar(context, 'Lỗi: $e', isError: true);
      }
    }
  }

  String _getBio() {
    final bio = _stringValue(_user?['bio']).trim();
    if (bio.isNotEmpty) return bio;
    return AppStrings.get('noBioYet');
  }

  String _getBirthYear() {
    final dateOfBirth = _user?['dateOfBirth'];
    if (dateOfBirth == null) return AppStrings.get('noYearOfBirth');
    try {
      final date = DateTime.parse(dateOfBirth);
      return date.year.toString();
    } catch (e) {
      return AppStrings.get('noYearOfBirth');
    }
  }

  Future<void> _showEditBioDialog() async {
    final TextEditingController bioController = TextEditingController(
      text: _stringValue(_user?['bio']).trim(),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.get('editBio')),
        backgroundColor: Theme.of(context).cardColor,
        content: TextField(
          controller: bioController,
          maxLines: 3,
          maxLength: 25,
          decoration: InputDecoration(
            hintText: AppStrings.get('enterBio'),
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
            child: Text(AppStrings.get('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.get('save')),
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
          _showCustomSnackBar(context, AppStrings.get('bioUpdated'));
        }
      } catch (e) {
        if (mounted) {
          _showCustomSnackBar(context, 'Lỗi: $e', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
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
                                ? AppStrings.get('uploading')
                                : AppStrings.get('changeAvatar'),
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
                      title: AppStrings.get('myProfile'),
                      subtitle: AppStrings.get('viewEditInfo'),
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
                                    AppStrings.get('volunteerStatus'),
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
                                          ? AppStrings.get('readyForRequests')
                                          : AppStrings.get('notReceivingSOS'),
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
                                              _showCustomSnackBar(
                                                context,
                                                newReadyStatus
                                                    ? AppStrings.get('sosRequestOn')
                                                    : AppStrings.get('sosRequestOff'),
                                                isError: !newReadyStatus,
                                              );
                                            } catch (e) {
                                              setState(() {
                                                _isTogglingReady = false;
                                              });
                                              if (!mounted) return;
                                              _showCustomSnackBar(
                                                context,
                                                'Lỗi: $e',
                                                isError: true,
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
                                title: AppStrings.get('viewVolunteerProfile'),
                                subtitle: AppStrings.get('manageVolunteerProfile'),
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
                            title: AppStrings.get('pendingApproval'),
                            subtitle: AppStrings.get('waitForAdmin'),
                            // iconColor: Colors.orange, // Helper chưa hỗ trợ iconColor, cần sửa helper hoặc bỏ qua
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(AppStrings.get('underReview')),
                                  content: Text(
                                    AppStrings.get('underReviewContent'),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text(AppStrings.get('close')),
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
                            title: AppStrings.get('registrationRejected'),
                            subtitle: AppStrings.get('tapToReregister'),
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
                          title: AppStrings.get('becomeVolunteer'),
                          subtitle: AppStrings.get('joinRescueCommunity'),
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
                      title: AppStrings.get('settings'),
                      subtitle: AppStrings.get('customizeApp'),
                      onTap: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),
                    const SizedBox(height: 12),

                    // Menu "Đăng bài viết" - chỉ hiển thị cho TNV và ADMIN
                    Builder(
                      builder: (context) {
                        final roles = _user?['roles'];
                        bool canCreateArticle = false;

                        if (roles is List) {
                          canCreateArticle =
                              roles.contains('TNV_CN') ||
                              roles.contains('TNV_TC') ||
                              roles.contains('ADMIN');
                        } else if (roles is String) {
                          canCreateArticle =
                              roles == 'TNV_CN' ||
                              roles == 'TNV_TC' ||
                              roles == 'ADMIN';
                        }

                        if (!canCreateArticle) {
                          return const SizedBox.shrink(); // Không hiển thị gì
                        }

                        return Column(
                          children: [
                            _buildAccountTile(
                              context,
                              icon: Icons.create_outlined,
                              title: AppStrings.get('createPost'),
                              subtitle: AppStrings.get('createPostSubtitle'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CreateArticleScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    ),

                    _buildAccountTile(
                      context,
                      icon: Icons.info_outline,
                      title: AppStrings.get('aboutApp'),
                      subtitle: AppStrings.get('versionInfo'),
                      onTap: () => _showAboutDialog(context),
                    ),
                    const SizedBox(height: 130),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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

  Future<void> _showAboutDialog(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [
                      const Color(0xFF1A237E),
                      const Color(0xFF0D47A1),
                    ]
                  : [
                      const Color(0xFFFFF8E1),
                      const Color(0xFFFFE082),
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with App Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // App Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.phone_in_talk,
                        size: 48,
                        color: Color(0xFFF57F17),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // App Name
                    Text(
                      'SOS_App',
                      style: GoogleFonts.montserrat(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF0D47A1),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Version Info
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Phiên bản ${packageInfo.version} (${packageInfo.buildNumber})',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : const Color(0xFF1565C0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Description
                    Text(
                      'Ứng dụng cứu hộ cộng đồng',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF0D47A1),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kết nối người cần trợ giúp với tình nguyện viên gần nhất trong thời gian thực.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Features Icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFeatureIcon(
                          context,
                          Icons.emergency,
                          'SOS\nNhanh',
                        ),
                        _buildFeatureIcon(
                          context,
                          Icons.volunteer_activism,
                          'Tình\nNguyện',
                        ),
                        _buildFeatureIcon(
                          context,
                          Icons.map,
                          'Bản đồ\nThực tế',
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Credits
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.favorite,
                                size: 16,
                                color: Colors.red.shade400,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Phát triển bởi Team SOS_app:\nHoàng Nhớ,Quang Thi ,Hoàng Anh ',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white70
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '© 2024 SafeConnect. All rights reserved.',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white54
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Close Button
              Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF0D47A1),
                      foregroundColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF0D47A1)
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      'Đóng',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureIcon(BuildContext context, IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 28,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFFF57F17),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.grey.shade700,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  void _showCustomSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        backgroundColor: isError
            ? Colors.red.withOpacity(0.9)
            : const Color(0xFF333333).withOpacity(0.95),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
