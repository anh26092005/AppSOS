import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final PostService _postService = PostService();
  late PostModel _currentPost;
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    debugPrint('Post isLiked: ${_currentPost.isLiked}');
  }

  Future<void> _handleLike() async {
    if (_isLiking) return;

    setState(() => _isLiking = true);

    try {
      final updatedPost = await _postService.toggleLike(
        _currentPost.id,
        _currentPost.isLiked,
      );

      if (mounted) {
        setState(() {
          _currentPost = updatedPost;
          _isLiking = false;
        });
        debugPrint('Updated post isLiked: ${_currentPost.isLiked}');
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      if (mounted) {
        setState(() => _isLiking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể cập nhật lượt thích')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _calculateReadingTime(String content) {
    final wordCount = content.split(RegExp(r'\s+')).length;
    final readTime = (wordCount / 200).ceil();
    return '$readTime phút đọc';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark
        ? Colors.grey.shade400
        : Colors.grey.shade700;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withValues(
              alpha: 0.8,
            ),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context, _currentPost),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: _isLiking ? null : _handleLike,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _currentPost.isLiked
                    ? Colors.red.withValues(alpha: 0.15)
                    : (isDark ? Colors.black : Colors.white).withValues(
                        alpha: 0.8,
                      ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _currentPost.isLiked
                      ? Colors.red.withValues(alpha: 0.3)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _currentPost.isLiked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: _currentPost.isLiked ? Colors.red : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_currentPost.likeCount}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _currentPost.isLiked ? Colors.red : textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF2D2500),
                    Color(0xFF1E1E1E),
                    Color(0xFF1E1E1E),
                  ],
                  stops: [0.0, 0.3, 1.0],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF8E1), Colors.white, Colors.white],
                  stops: [0.0, 0.3, 1.0],
                ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentPost.contentText,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_calculateReadingTime(_currentPost.bodyContent)} | ${_formatDate(_currentPost.createdAt)}',
                  style: TextStyle(fontSize: 12, color: secondaryTextColor),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color.fromRGBO(
                          246,
                          195,
                          67,
                          1,
                        ).withValues(alpha: 0.2),
                      ),
                      child: _currentPost.authorAvatar != null
                          ? ClipOval(
                              child: Image.network(
                                _currentPost.authorAvatar!,
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
                    Text(
                      _currentPost.authorName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_currentPost.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      _currentPost.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                        child: Icon(
                          Icons.broken_image,
                          color: isDark ? Colors.grey.shade600 : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                ..._currentPost.bodyContent.split('\r\n\r\n').map((paragraph) {
                  if (paragraph.trim().isEmpty) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      paragraph.trim(),
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark
                            ? Colors.grey.shade300
                            : const Color(0xFF333333),
                        height: 1.6,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
