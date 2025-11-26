import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/post_model.dart';

class PostDetailScreen extends StatelessWidget {
  final PostModel post;

  const PostDetailScreen({super.key, required this.post});

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 24),
                Text(
                  '${post.likeCount} lượt thích',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              post.contentText, // Headline
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),

            // Metadata
            Text(
              '${_calculateReadingTime(post.bodyContent)} | ${_formatDate(post.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Author
            Row(
              children: [
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
                Text(
                  post.authorName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Main Image
            if (post.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Content Body
            // Xử lý hiển thị nội dung: Tách các đoạn văn bản
            ...post.bodyContent.split('\r\n\r\n').map((paragraph) {
              if (paragraph.trim().isEmpty) return const SizedBox.shrink();

              // Kiểm tra xem đoạn văn có phải là heading không (giả định đơn giản: ngắn và không có dấu chấm câu cuối cùng, hoặc viết hoa hết - tùy data, ở đây hiển thị text thường nhưng đậm hơn chút nếu ngắn)
              // Với data mẫu, các heading như "Dọn nội thất..." không có định dạng đặc biệt trong JSON text thuần.
              // Ta sẽ hiển thị text bình thường với line height tốt để dễ đọc.

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  paragraph.trim(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF333333),
                    height: 1.6,
                  ),
                ),
              );
            }),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
