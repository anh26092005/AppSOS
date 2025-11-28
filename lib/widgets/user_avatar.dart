import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

enum AvatarSize {
  small(48),
  medium(80),
  large(120);

  final double size;
  const AvatarSize(this.size);
}

/// Reusable avatar widget with loading, error, and default states
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final AvatarSize size;
  final bool showEditButton;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    required this.name,
    this.size = AvatarSize.medium,
    this.showEditButton = false,
    this.onTap,
  });

  String _getInitial() {
    if (name.isEmpty) return '?';
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final sizeValue = size.size;
    final borderWidth = size == AvatarSize.large ? 4.0 : 2.0;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: sizeValue,
            height: sizeValue,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: borderWidth),
              color: const Color(0xFFF6C343).withValues(alpha: 0.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: size == AvatarSize.large ? 10 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: avatarUrl != null
                  ? Image.network(
                      avatarUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        // Shimmer skeleton while loading
                        return Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(
                            width: sizeValue,
                            height: sizeValue,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                    )
                  : _buildDefaultAvatar(),
            ),
          ),
          if (showEditButton)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6C343),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: size.size,
      height: size.size,
      color: Colors.grey.shade200,
      child: Center(
        child: Text(
          _getInitial(),
          style: TextStyle(
            fontSize: size == AvatarSize.large
                ? 40
                : size == AvatarSize.medium
                ? 32
                : 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
