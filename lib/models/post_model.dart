class PostModel {
  final String id;
  final String authorId;
  final String authorType; // "user" or "group"
  final String authorName;
  final String? authorAvatar;
  final DateTime createdAt;
  final String contentText;
  final String? imageUrl;
  final int likeCount;
  final bool isLiked;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorType,
    required this.authorName,
    this.authorAvatar,
    required this.createdAt,
    required this.contentText,
    this.imageUrl,
    required this.likeCount,
    required this.isLiked,
  });

  PostModel copyWith({
    String? id,
    String? authorId,
    String? authorType,
    String? authorName,
    String? authorAvatar,
    DateTime? createdAt,
    String? contentText,
    String? imageUrl,
    int? likeCount,
    bool? isLiked,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorType: authorType ?? this.authorType,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      createdAt: createdAt ?? this.createdAt,
      contentText: contentText ?? this.contentText,
      imageUrl: imageUrl ?? this.imageUrl,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      authorType: json['authorType'] as String,
      authorName: json['authorName'] as String,
      authorAvatar: json['authorAvatar'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      contentText: json['contentText'] as String,
      imageUrl: json['imageUrl'] as String?,
      likeCount: json['likeCount'] as int,
      isLiked: json['isLiked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorId': authorId,
      'authorType': authorType,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'createdAt': createdAt.toIso8601String(),
      'contentText': contentText,
      'imageUrl': imageUrl,
      'likeCount': likeCount,
      'isLiked': isLiked,
    };
  }
}

