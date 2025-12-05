import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service để quản lý âm thanh thông báo
class NotificationSoundService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isPlaying = false;

  /// Phát âm thanh thông báo
  ///
  /// Sử dụng file notification.mp3 từ assets/sounds/
  static Future<void> playNotificationSound() async {
    try {
      // Dừng âm thanh đang phát (nếu có)
      if (_isPlaying) {
        await stopSound();
      }

      _isPlaying = true;

      // Phát file âm thanh custom từ assets
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));

      if (kDebugMode) {
        print('🔊 Notification sound played (custom: notification.mp3)');
      }

      // Lắng nghe khi âm thanh phát xong
      _audioPlayer.onPlayerComplete.listen((event) {
        _isPlaying = false;
        if (kDebugMode) {
          print('✅ Notification sound completed');
        }
      });
    } catch (e) {
      _isPlaying = false;
      if (kDebugMode) {
        print('❌ Error playing notification sound: $e');
      }
    }
  }

  /// Dừng phát âm thanh
  static Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      if (kDebugMode) {
        print('🔇 Notification sound stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error stopping sound: $e');
      }
    }
  }

  /// Giải phóng tài nguyên
  static Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      if (kDebugMode) {
        print('🗑️ AudioPlayer disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error disposing AudioPlayer: $e');
      }
    }
  }

  /// Set âm lượng (0.0 - 1.0)
  static Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
      if (kDebugMode) {
        print('🔊 Volume set to: $volume');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting volume: $e');
      }
    }
  }
}
