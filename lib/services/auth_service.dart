import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service class to handle Firebase Authentication operations
/// Supports Google Sign-In
class AuthService {
  // Firebase Auth instance
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Google
  /// Returns UserCredential on success, throws Exception on failure
  static Future<UserCredential> signInWithGoogle() async {
    try {
      // Initialize Google Sign-In
      await GoogleSignIn.instance.initialize();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance
          .authenticate();

      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled by user');
      }

      // Get authentication tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential (only idToken is available in v7.x)
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }





  /// Sign out from Firebase and all social providers
  static Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _auth.signOut();

      // Sign out from Google - Using attemptLightweightAuthentication to check
      try {
        final account = await GoogleSignIn.instance
            .attemptLightweightAuthentication();
        if (account != null) {
          await GoogleSignIn.instance.signOut();
        }
      } catch (e) {
        // Ignore if not signed in
        print('Google sign out skipped: $e');
      }


    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// Get current user details as a Map
  /// Returns null if no user is signed in
  static Map<String, dynamic>? getCurrentUserDetails() {
    final user = currentUser;
    if (user == null) return null;

    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'phoneNumber': user.phoneNumber,
      'photoURL': user.photoURL,
      'isEmailVerified': user.emailVerified,
      'isAnonymous': user.isAnonymous,
    };
  }

  /// Check if a user is currently signed in
  static bool isUserSignedIn() {
    return currentUser != null;
  }
}
