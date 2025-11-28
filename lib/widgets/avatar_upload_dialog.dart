import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dialog to select avatar source (Camera or Gallery)
class AvatarUploadDialog {
  static Future<XFile?> show(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    return showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Chọn ảnh đại diện',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Camera option
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.blue,
                          ),
                        ),
                        title: Text(
                          'Chụp ảnh',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Sử dụng camera',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        onTap: () async {
                          final image = await picker.pickImage(
                            source: ImageSource.camera,
                            maxWidth: 1024,
                            maxHeight: 1024,
                            imageQuality: 85,
                          );
                          if (context.mounted) {
                            Navigator.pop(context, image);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      // Gallery option
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.photo_library,
                            color: Colors.green,
                          ),
                        ),
                        title: Text(
                          'Chọn từ thư viện',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Chọn ảnh có sẵn',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        onTap: () async {
                          final image = await picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 1024,
                            maxHeight: 1024,
                            imageQuality: 85,
                          );
                          if (context.mounted) {
                            Navigator.pop(context, image);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      // Cancel button
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          'Hủy',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
