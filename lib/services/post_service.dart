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
    // TODO: Implement API call for like
    // For now, return a mock updated post to update UI immediately
    // In real implementation: await ApiService.likePost(postId);

    // Tạm thời throw error hoặc return dummy để UI không crash,
    // nhưng vì không có full post data ở đây để return,
    // nên tốt nhất là UI nên handle optimistic update hoặc fetch lại.
    // Tuy nhiên, để đơn giản, ta sẽ giả định thành công và trả về post đã update (nếu có thể lấy từ cache)
    // Nhưng service này hiện không cache _allPosts nữa.

    // Giải pháp: Gọi API like, sau đó fetch lại post detail hoặc trả về status.
    // Vì hàm này yêu cầu trả về PostModel, ta cần fetch lại post đó.

    throw UnimplementedError(
      'Like feature not fully implemented with backend yet',
    );
  }

  /// Check if there are more posts to load
  bool hasMorePosts(int currentPage, int pageSize) {
    // Logic này hơi khó khi fetch từ API mà không biết total pages.
    // Tạm thời return true, trừ khi lần fetch trước trả về ít hơn limit.
    return true;
  }
}
