import 'dart:math';
import '../models/post_model.dart';

/// Service for fetching posts from backend
/// In production, this would call REST API, Firebase, or GraphQL
class PostService {
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;
  
  final List<PostModel> _allPosts = [];
  int _currentPage = 0;

  PostService._internal() {
    // Initialize with mock data
    _generateMockPosts();
  }

  void _generateMockPosts() {
    final authors = [
      {'name': 'Nhóm thiện nguyện Hà Tĩnh', 'type': 'group'},
      {'name': 'Nhóm thiện nguyện Q.9', 'type': 'group'},
      {'name': 'Nguyễn Văn A', 'type': 'user'},
      {'name': 'Trần Thị B', 'type': 'user'},
      {'name': 'Hội từ thiện Sài Gòn', 'type': 'group'},
    ];

    final contents = [
      'Đồ ăn cứu trợ đồng bào vùng bão lũ: Nên gửi gì và bảo quản thế nào?',
      'Chú Long quận 9\' và hành trình 15 năm rong ruổi giúp đời',
      'Cảm ơn các mạnh thường quân đã hỗ trợ cho chương trình thiện nguyện',
      'Chia sẻ kinh nghiệm tổ chức hoạt động tình nguyện hiệu quả',
      'Kêu gọi quyên góp cho trẻ em vùng cao',
    ];

    final random = Random();
    final now = DateTime.now();

    for (int i = 0; i < 30; i++) {
      final author = authors[random.nextInt(authors.length)];
      _allPosts.add(PostModel(
        id: 'post_$i',
        authorId: 'author_${random.nextInt(100)}',
        authorType: author['type'] as String,
        authorName: author['name'] as String,
        authorAvatar: null,
        createdAt: now.subtract(Duration(hours: random.nextInt(48))),
        contentText: contents[random.nextInt(contents.length)],
        imageUrl: random.nextBool() ? 'https://picsum.photos/400/300?random=$i' : null,
        likeCount: random.nextInt(1000),
        isLiked: random.nextBool(),
      ));
    }

    // Sort by creation date (newest first)
    _allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Fetch posts with pagination
  Future<List<PostModel>> fetchPosts({
    int page = 0,
    int limit = 10,
    bool refresh = false,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (refresh) {
      _currentPage = 0;
    }

    final startIndex = page * limit;
    final endIndex = (startIndex + limit).clamp(0, _allPosts.length);

    if (startIndex >= _allPosts.length) {
      return [];
    }

    return _allPosts.sublist(startIndex, endIndex);

    /* Production code example:
    final response = await http.get(
      Uri.parse('$baseUrl/posts?page=$page&limit=$limit'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    final data = json.decode(response.body);
    return (data['posts'] as List)
        .map((json) => PostModel.fromJson(json))
        .toList();
    */
  }

  /// Toggle like status for a post
  Future<PostModel> toggleLike(String postId, bool currentLikeStatus) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));

    final postIndex = _allPosts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) {
      throw Exception('Post not found');
    }

    final post = _allPosts[postIndex];
    final updatedPost = post.copyWith(
      isLiked: !currentLikeStatus,
      likeCount: currentLikeStatus ? post.likeCount - 1 : post.likeCount + 1,
    );

    _allPosts[postIndex] = updatedPost;

    return updatedPost;

    /* Production code example:
    final response = await http.post(
      Uri.parse('$baseUrl/posts/$postId/like'),
      headers: {'Authorization': 'Bearer $token'},
      body: json.encode({'like': !currentLikeStatus}),
    );
    
    final data = json.decode(response.body);
    return PostModel.fromJson(data);
    */
  }

  /// Check if there are more posts to load
  bool hasMorePosts(int currentPage, int pageSize) {
    return (currentPage + 1) * pageSize < _allPosts.length;
  }
}

