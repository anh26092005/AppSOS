import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';
import 'fcm_service.dart';

/// Service to sync Firebase Auth users with backend API
class SocialAuthApi {
  /// Sync social login (Google/Facebook/Phone) with backend
  ///
  /// This method:
  /// 1. Takes Firebase user data
  /// 2. Sends it to backend /api/auth/social-login
  /// 3. Backend creates or updates user record
  /// 4. Returns JWT token for backend authentication
  /// 5. Saves token to ApiService for future requests
  static Future<Map<String, dynamic>> syncSocialLogin(
    User firebaseUser,
    String provider, // 'google', 'facebook', or 'phone'
  ) async {
    try {
      // Prepare request data
      final requestBody = {
        'firebaseUid': firebaseUser.uid,
        'displayName': firebaseUser.displayName ?? 'User',
        'email': firebaseUser.email,
        'photoURL': firebaseUser.photoURL,
        'provider': provider,
      };

      print('🔄 Syncing Firebase user to backend...');
      print('   Provider: $provider');
      print('   Firebase UID: ${firebaseUser.uid}');
      print('   Name: ${firebaseUser.displayName}');
      print('   Email: ${firebaseUser.email}');

      // Call backend API
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/social-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        final token = data['token'];
        final user = data['user'];
        final isNewUser = data['isNewUser'] ?? false;

        print('✅ Backend sync successful!');
        print('   Backend User ID: ${user['_id']}');
        print('   Is New User: $isNewUser');

        // Save token to ApiService for authenticated requests
        await ApiService.setToken(token);
        await ApiService.saveUser(user);

        return {
          'success': true,
          'token': token,
          'user': user,
          'isNewUser': isNewUser,
        };
      } else {
        // Error response from backend
        final errorMessage = data['message'] ?? 'Social login sync failed';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Backend sync failed: $e');
      throw Exception('Failed to sync with backend: $e');
    }
  }

  /// Sign out from both Firebase and backend
  static Future<void> signOutComplete() async {
    try {
      // [FIX] Unregister FCM token from backend FIRST
      // This prevents old account from receiving notifications
      final fcmToken = FCMService.currentToken;
      if (fcmToken != null) {
        print('🔓 Unregistering FCM token from backend...');
        try {
          await ApiService.unregisterDevice(fcmToken);
          print('✅ FCM token unregistered from backend');
        } catch (e) {
          print('⚠️ Failed to unregister FCM token (continuing logout): $e');
          // Don't block logout if API call fails
        }
      }

      // Delete FCM token locally
      await FCMService.deleteToken();

      // Clear backend session
      await ApiService.clearSession();

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      print(
        '✅ Signed out completely - FCM token removed, Firebase signed out, session cleared',
      );
    } catch (e) {
      print('❌ Sign out error: $e');
      throw Exception('Sign out failed: $e');
    }
  }
}
