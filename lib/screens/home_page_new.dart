import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../services/post_service.dart';
import '../services/api_service.dart';
import '../widgets/skeleton_widgets.dart';
import '../widgets/skeleton_post.dart';
import 'post_detail_screen.dart';

class HomePageNew extends StatefulWidget {
  const HomePageNew({super.key});

  @override
  State<HomePageNew> createState() => _HomePageNewState();
}

class _HomePageNewState extends State<HomePageNew> {
  final WeatherService _weatherService = WeatherService();
  final PostService _postService = PostService();
  final ScrollController _scrollController = ScrollController();

  WeatherModel? _weather;
  bool _isLoadingWeather = true;

  List<PostModel> _posts = [];
  int _currentPage = 0;
  bool _isLoadingPosts = false;
  bool _hasMorePosts = true;
  final int _pageSize = 10;

  String _userName = 'Bạn';
  String? _userAvatar; // Avatar URL from user profile
  String? _lunarDate; // Ngày âm lịch

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.8) {
        _loadMorePosts();
      }
    });
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadUserProfile(),
      _fetchWeather(),
      _fetchPosts(refresh: true),
      _fetchLunarDate(),
    ]);
  }

  Future<void> _fetchLunarDate() async {
    try {
      final now = DateTime.now();
      final response = await http.post(
        Uri.parse('https://open.oapi.vn/date/convert-to-lunar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'day': now.day,
          'month': now.month,
          'year': now.year,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 'success' && mounted) {
          final lunarData = data['data'];
          setState(() {
            _lunarDate = '${lunarData['day']}/${lunarData['month']}';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching lunar date: $e');
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await ApiService.getCachedUser();
      if (user != null && mounted) {
        setState(() {
          _userName = user['fullName'] ?? 'Bạn';
          _userAvatar = _getAvatarUrl(user['avatar']);
        });
      } else {
        // Nếu chưa có cache, thử fetch mới
        final newUser = await ApiService.fetchProfile();
        if (mounted) {
          setState(() {
            _userName = newUser['fullName'] ?? 'Bạn';
            _userAvatar = _getAvatarUrl(newUser['avatar']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  /// Helper to extract avatar URL from various formats
  String? _getAvatarUrl(dynamic avatar) {
    if (avatar == null) return null;
    if (avatar is String) return avatar;
    if (avatar is Map<String, dynamic>) {
      return avatar['url'] as String?;
    }
    return null;
  }

  Future<void> _fetchWeather() async {
    setState(() => _isLoadingWeather = true);
    try {
      final weather = await _weatherService.fetchWeatherAuto();
      if (mounted) {
        setState(() {
          _weather = weather;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingWeather = false);
      }
      debugPrint('Error fetching weather: $e');
    }
  }

  Future<void> _fetchPosts({bool refresh = false}) async {
    if (_isLoadingPosts || (!_hasMorePosts && !refresh)) return;

    setState(() {
      _isLoadingPosts = true;
      if (refresh) {
        _currentPage = 0;
        _hasMorePosts = true;
      }
    });

    try {
      final newPosts = await _postService.fetchPosts(
        page: refresh ? 0 : _currentPage,
        limit: _pageSize,
        refresh: refresh,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _posts = newPosts;
          } else {
            _posts.addAll(newPosts);
          }
          _currentPage++;
          _hasMorePosts = newPosts.length >= _pageSize;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPosts = false);
      }
      debugPrint('Error fetching posts: $e');
    }
  }

  Future<void> _loadMorePosts() async {
    if (!_isLoadingPosts && _hasMorePosts) {
      await _fetchPosts();
    }
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      _loadUserProfile(),
      _fetchWeather(),
      _fetchPosts(refresh: true),
    ]);
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
      _showCustomSnackBar(
        context,
        'Không thể cập nhật lượt thích',
        isError: true,
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Chúc bạn sáng vui vẻ';
    } else if (hour >= 12 && hour < 18) {
      return 'Chúc bạn chiều vui vẻ';
    } else {
      return 'Chúc bạn tối vui vẻ';
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
    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: const Color(0xFFF6C343),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Animated Header Section
              SliverPersistentHeader(
                pinned: true,
                delegate: _HomeHeaderDelegate(
                  userName: _userName,
                  userAvatar: _userAvatar,
                  greeting: greeting,
                  weatherCard: _buildWeatherCard(),
                  lunarDate: _lunarDate,
                ),
              ),

              // Posts Feed
              if (_posts.isEmpty && _isLoadingPosts)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const SkeletonPost(),
                    childCount: 3,
                  ),
                )
              else if (_posts.isEmpty && !_isLoadingPosts)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Chưa có bài viết nào',
                      style: TextStyle(color: Color(0xFF777777)),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == _posts.length) {
                      // Loading indicator at bottom
                      if (_isLoadingPosts) {
                        return const SkeletonPost();
                      }
                      return const SizedBox.shrink();
                    }
                    return _buildPostCard(_posts[index]);
                  }, childCount: _posts.length + (_isLoadingPosts ? 1 : 0)),
                ),
              // Padding bottom để nội dung không bị che bởi navbar
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    if (_isLoadingWeather) {
      return const SkeletonWeather();
    }

    if (_weather == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text('Không thể tải thông tin thời tiết'),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Side: Location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Thời tiết tại',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _weather!.locationName,
                  style: GoogleFonts.balooBhaina2(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Right Side: Details & Temp
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Mưa: ${_weather!.humidity}%, Gió: ${_weather!.windSpeed.toStringAsFixed(0)} km/h',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${_weather!.temperature.toStringAsFixed(0)}°C',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _weather!.weatherIcon,
                    style: const TextStyle(fontSize: 32),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(PostModel post) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 7,
            offset: const Offset(0, 0),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () async {
            final updatedPost = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailScreen(post: post),
              ),
            );

            if (updatedPost != null && mounted) {
              setState(() {
                final index = _posts.indexWhere((p) => p.id == post.id);
                if (index != -1) {
                  _posts[index] = updatedPost as PostModel;
                }
              });
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author Info
              Padding(
                padding: const EdgeInsets.all(16),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/volunteer-profile',
                                    arguments: {
                                      'id': post.authorId,
                                      'name': post.authorName,
                                      'avatar': post.authorAvatar,
                                    },
                                  );
                                },
                                child: Text(
                                  post.authorName,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                              if (post.authorType == 'group') ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFF6C343,
                                    ).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.group,
                                    size: 12,
                                    color: Color(0xFFF6C343),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            _formatTimeAgo(post.createdAt),
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
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
                        padding: const EdgeInsets.symmetric(
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
                            const SizedBox(width: 6),
                            Text(
                              '${post.likeCount}',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
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
                            height: 200,
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
                          height: 200,
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

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String userName;
  final String? userAvatar;
  final String greeting;
  final Widget weatherCard;
  final String? lunarDate;

  _HomeHeaderDelegate({
    required this.userName,
    this.userAvatar,
    required this.greeting,
    required this.weatherCard,
    this.lunarDate,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final date = DateFormat('dd/MM').format(DateTime.now());
    // 0.0 -> 1.0
    final progress = shrinkOffset / maxExtent;
    final contentOpacity = (1 - (progress * 2)).clamp(0.0, 1.0);
    final titleAlignment = Alignment.lerp(
      Alignment.bottomLeft,
      Alignment.bottomCenter,
      progress,
    )!;
    final titlePaddingLeft = 20.0 * (1 - progress);

    return Container(
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Content (Greeting + Weather)
          Positioned(
            top: 16 - shrinkOffset * 0.5,
            left: 20,
            right: 20,
            bottom: 60,
            child: Opacity(
              opacity: contentOpacity,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Xin chào, $userName',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w800,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF0D47A1),
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                greeting,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // User Avatar
                        Container(
                          width: 40.w,
                          height: 40.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            color: const Color(
                              0xFFF6C343,
                            ).withValues(alpha: 0.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8.r,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: userAvatar != null
                                ? Image.network(
                                    userAvatar!,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Shimmer.fromColors(
                                            baseColor: Colors.grey.shade300,
                                            highlightColor:
                                                Colors.grey.shade100,
                                            child: Container(
                                              width: 48.w,
                                              height: 48.h,
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
                                      size: 24,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    color: Color(0xFFF6C343),
                                    size: 24,
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    weatherCard,
                  ],
                ),
              ),
            ),
          ),

          // Title "Bản tin"
          Align(
            alignment: titleAlignment,
            child: Padding(
              padding: EdgeInsets.only(
                left: titlePaddingLeft,
                bottom: 12,
                right: 20 * (1 - progress),
              ),
              child: Text(
                'Bản tin',
                style: GoogleFonts.montserrat(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.blueAccent
                      : const Color.fromARGB(255, 6, 82, 158),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // Lunar Date (Âm lịch) - Positioned separately
          if (lunarDate != null)
            Positioned(
              right: 20,
              bottom: 14, // Align visually with "Bản tin"
              child: Opacity(
                opacity: contentOpacity,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.blueAccent.withValues(alpha: 0.2)
                        : const Color(0xFF0D47A1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.blueAccent.withValues(alpha: 0.3)
                          : const Color(0xFF0D47A1).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'DL: $date - ÂL: $lunarDate',
                    style: GoogleFonts.montserrat(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.blueAccent
                          : const Color(0xFF0D47A1),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 250; // Reduced from 300 to decrease gap

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate oldDelegate) {
    return oldDelegate.greeting != greeting ||
        oldDelegate.weatherCard != weatherCard ||
        oldDelegate.userName != userName ||
        oldDelegate.lunarDate != lunarDate;
  }
}
