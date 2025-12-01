import '../models/post_model.dart';
import '../services/api_service.dart';

/// Service for fetching posts from backend
class PostService {
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;

  PostService._internal();

  /// Fetch posts with pagination
  Future<List<PostModel>> fetchPosts({
    int page = 0,
    int limit = 10,
    bool refresh = false,
    String? authorId,
  }) async {
    try {
      // ApiService.fetchBlogs uses 1-based page index
      final data = await ApiService.fetchBlogs(
        page: page + 1,
        limit: limit,
        authorId: authorId,
      );
      return data.map((e) => PostModel.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching posts: $e');
      return [];
    }
  }

  /// Toggle like status for a post
  Future<PostModel> toggleLike(String postId, bool currentLikeStatus) async {
    try {
      // Call backend API to toggle like
      final response = await ApiService.togglePostLike(postId);

      // Get the updated like status and count from response
      final data = response['data'];
      final isLiked = data['isLiked'] as bool;
      final likeCount = data['likeCount'] as int;

      // Fetch posts to get the full post data
      final posts = await fetchPosts(page: 0, limit: 100);
      final post = posts.firstWhere(
        (p) => p.id == postId,
        orElse: () => throw Exception('Post not found'),
      );

      // Create updated post with correct like status from API response
      return post.copyWith(isLiked: isLiked, likeCount: likeCount);
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }

  /// Check if there are more posts to load
  bool hasMorePosts(int currentPage, int pageSize) {
    // Logic này hơi khó khi fetch từ API mà không biết total pages.
    // Tạm thời return true, trừ khi lần fetch trước trả về ít hơn limit.
    return true;
  }
}
