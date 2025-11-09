import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/post_model.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../services/post_service.dart';

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
      _fetchWeather(),
      _fetchPosts(refresh: true),
    ]);
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
          _hasMorePosts = _postService.hasMorePosts(_currentPage, _pageSize);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể cập nhật lượt thích')),
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: const Color(0xFFF6C343),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Header Section
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFCEFD8), // Light cream
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Status Bar (Time)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('HH:mm').format(now),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.signal_cellular_4_bar,
                                  size: 18,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.battery_full,
                                  size: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Greeting Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Xin chào, UTH Team',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    greeting,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF777777),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Avatar
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFF6C343).withValues(alpha: 0.2),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFFF6C343),
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Weather Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _buildWeatherCard(),
                ),
              ),

              // Section Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Text(
                    'Bản tin',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ),

              // Posts Feed
              if (_posts.isEmpty && !_isLoadingPosts)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Chưa có bài viết nào',
                      style: TextStyle(
                        color: Color(0xFF777777),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == _posts.length) {
                        // Loading indicator at bottom
                        if (_isLoadingPosts) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      return _buildPostCard(_posts[index]);
                    },
                    childCount: _posts.length + (_isLoadingPosts ? 1 : 0),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    if (_isLoadingWeather) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_weather == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thời tiết tại',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF777777),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _weather!.locationName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Độ ẩm: ${_weather!.humidity}%, Gió: ${_weather!.windSpeed.toStringAsFixed(1)} km/h',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF777777),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                _weather!.weatherIcon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 4),
              Text(
                '${_weather!.temperature.toStringAsFixed(0)}°C',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(PostModel post) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF6C343).withValues(alpha: 0.2),
                  ),
                  child: post.authorAvatar != null
                      ? ClipOval(
                          child: Image.network(
                            post.authorAvatar!,
                            fit: BoxFit.cover,
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
                          Text(
                            post.authorName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
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
                                color: const Color(0xFFF6C343).withValues(alpha: 0.2),
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
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF777777),
                        ),
                      ),
                    ],
                  ),
                ),
                // Like Button
                InkWell(
                  onTap: () => _handleLike(post),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          post.isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: post.isLiked ? Colors.red : const Color(0xFF777777),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.likeCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: post.isLiked ? Colors.red : const Color(0xFF777777),
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
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF333333),
                  height: 1.5,
                ),
              ),
            ),

          // Image
          if (post.imageUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Image.network(
                post.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.broken_image,
                    size: 60,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],

          // View Post Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Navigate to post detail
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Xem bài viết: ${post.id}')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF6C343),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Xem bài viết',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

