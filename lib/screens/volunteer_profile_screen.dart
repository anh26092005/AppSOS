import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../widgets/skeleton_post.dart';
import 'dart:io';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'post_detail_screen.dart';
import '../services/api_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VolunteerProfileScreen extends StatefulWidget {
  final Map<String, dynamic> volunteerData;

  const VolunteerProfileScreen({super.key, required this.volunteerData});

  @override
  State<VolunteerProfileScreen> createState() => _VolunteerProfileScreenState();
}

class _VolunteerProfileScreenState extends State<VolunteerProfileScreen> {
  final PostService _postService = PostService();
  List<PostModel> _posts = [];
  bool _isLoadingPosts = true;
  Map<String, dynamic>? _volunteerProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_fetchVolunteerPosts(), _fetchVolunteerProfile()]);
  }

  Future<void> _fetchVolunteerProfile() async {
    try {
      final profile = await ApiService.fetchVolunteerProfile(
        widget.volunteerData['id'],
      );
      if (mounted) {
        setState(() {
          _volunteerProfile = profile;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
      debugPrint('Error fetching volunteer profile: $e');
    }
  }

  Future<void> _fetchVolunteerPosts() async {
    // In a real app, we would fetch posts by userId.
    // For now, we'll fetch recent posts and filter or mock.
    // Since the API might not support filtering by user yet,
    // we will fetch general posts and filter client-side or just show some posts for demo.
    try {
      final posts = await _postService.fetchPosts(
        page: 0,
        limit: 10,
        authorId: widget.volunteerData['id'],
      );
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPosts = false);
      }
      debugPrint('Error fetching volunteer posts: $e');
    }
  }

  Future<void> _handleLike(PostModel post) async {
    try {
      final updatedPost = await _postService.toggleLike(post.id, post.isLiked);
      if (!mounted) return;
      setState(() {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _posts[index] = updatedPost;
        }
      });
    } catch (e) {
      debugPrint('Error toggling like: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể cập nhật lượt thích')),
      );
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  String _sanitizeUrl(String url) {
    if (Platform.isAndroid) {
      if (url.contains('localhost')) {
        return url.replaceFirst('localhost', '10.0.2.2');
      }
      if (url.contains('127.0.0.1')) {
        return url.replaceFirst('127.0.0.1', '10.0.2.2');
      }
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final volunteer = widget.volunteerData;
    final name =
        volunteer['authorName'] ?? volunteer['name'] ?? 'Tình nguyện viên';
    final avatar = volunteer['authorAvatar'] ?? volunteer['avatar'];

    // Data from fetched profile
    final birthYear = '2004'; // Birth year not in profile yet, keeping mock
    final bio = 'Mờ cương tòiiiiiii'; // Bio not in profile yet, keeping mock

    String helpedCount = '0';
    String specialty = 'Chưa cập nhật';

    if (_volunteerProfile != null) {
      // Total cases
      if (_volunteerProfile!['reputation'] != null) {
        helpedCount =
            _volunteerProfile!['reputation']['totalCases']?.toString() ?? '0';
      }

      // Skills
      final skills = _volunteerProfile!['skills'] as List?;
      if (skills != null && skills.isNotEmpty) {
        specialty = skills.join(', ');
      }
    } else if (_isLoadingProfile) {
      helpedCount = '...';
      specialty = '...';
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 240, 240),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with Overlapping Avatar
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Curved Header Background
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                    bottom: 50,
                  ), // Space for content inside header
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(26),
                      bottomRight: Radius.circular(26),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1976D2).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(left: 0),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.5),
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
                            ],
                          ),
                        ),
                        // Name and Info
                        Transform.translate(
                          offset: const Offset(0, -25),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Column(
                              children: [
                                Text(
                                  name,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.balooBhaina2(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(
                                      255,
                                      255,
                                      255,
                                      255,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    birthYear,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color.fromARGB(
                                        255,
                                        255,
                                        255,
                                        255,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  bio,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    color: const Color.fromARGB(
                                      255,
                                      255,
                                      255,
                                      255,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40), // Space for stats
                      ],
                    ),
                  ),
                ),

                // Stats (Left and Right of Avatar)
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: SizedBox(
                    width: 100,
                    child: Text(
                      'Đã giúp đỡ\n$helpedCount người',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 233, 213, 37),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: SizedBox(
                    width: 100,
                    child: Text(
                      'Chuyên gia\n$specialty',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 233, 213, 37),
                      ),
                    ),
                  ),
                ),

                // Avatar (Overlapping)
                Positioned(
                  bottom: -60,
                  child: Container(
                    width: 130.w,
                    height: 130.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: avatar != null
                          ? Image.network(
                              avatar,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildPlaceholderAvatar(),
                            )
                          : _buildPlaceholderAvatar(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 70), // Space for avatar overlap
            // Posts List
            _isLoadingPosts
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 2,
                    itemBuilder: (context, index) => const SkeletonPost(),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(0),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      return _buildPostCard(context, _posts[index]);
                    },
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.person, size: 60, color: Colors.grey),
    );
  }

  Widget _buildPostCard(BuildContext context, PostModel post) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailScreen(post: post),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author Info
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF6C343).withValues(alpha: 0.2),
                      ),
                      child: post.authorAvatar != null
                          ? ClipOval(
                              child: Image.network(
                                post.authorAvatar!,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      // Shimmer skeleton while loading
                                      return Shimmer.fromColors(
                                        baseColor: Colors.grey.shade300,
                                        highlightColor: Colors.grey.shade100,
                                        child: Container(
                                          width: 44,
                                          height: 44,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    },
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person,
                                  color: Color(0xFFF6C343),
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              color: Color(0xFFF6C343),
                              size: 24,
                            ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                post.authorName,
                                style: GoogleFonts.montserrat(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                              ),
                              if (post.authorType == 'group') ...[
                                SizedBox(width: 6.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFF6C343,
                                    ).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Icon(
                                    Icons.group,
                                    size: 12,
                                    color: const Color(0xFFF6C343),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            _formatTimeAgo(post.createdAt),
                            style: GoogleFonts.montserrat(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF999999),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Like Button
                    InkWell(
                      onTap: () => _handleLike(post),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: post.isLiked
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              post.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 18,
                              color: post.isLiked
                                  ? Colors.red
                                  : const Color(0xFF777777),
                            ),
                            SizedBox(width: 6),
                            Text(
                              '${post.likeCount}',
                              style: GoogleFonts.montserrat(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: post.isLiked
                                    ? Colors.red
                                    : const Color(0xFF777777),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content Text
              if (post.contentText.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    post.contentText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      height: 1,
                    ),
                  ),
                ),

              // Image
              if (post.imageUrl != null) ...[
                SizedBox(height: 12.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.network(
                      _sanitizeUrl(post.imageUrl!),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(
                            height: 200.h,
                            width: double.infinity,
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint(
                          'Error loading image: ${_sanitizeUrl(post.imageUrl!)}',
                        );
                        debugPrint('Error details: $error');
                        return Container(
                          height: 200.h,
                          color: Colors
                              .grey
                              .shade300, // Darker grey for visibility
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.broken_image,
                                size: 40,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Lỗi tải ảnh',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // Footer (Read More Button)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 120.w, // Responsive width
                  vertical: 8.h, // Responsive height
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(
                      30.r,
                    ), // Responsive radius
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1976D2).withValues(alpha: 0.3),
                        blurRadius: 8.r,
                        offset: Offset(0, 3.h),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostDetailScreen(post: post),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(30.r),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Xem chi tiết',
                              style: GoogleFonts.montserrat(
                                fontSize: 10.sp, // Responsive font size
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 14.sp, // Responsive icon size
                            ),
                          ],
                        ),
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
}
